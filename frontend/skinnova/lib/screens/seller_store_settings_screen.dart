import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerStoreSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final String storeId;
  const SellerStoreSettingsScreen({
    super.key,
    required this.store,
    required this.storeId,
  });

  @override
  State<SellerStoreSettingsScreen> createState() =>
      _SellerStoreSettingsScreenState();
}

class _SellerStoreSettingsScreenState extends State<SellerStoreSettingsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── Existing fields ────────────────────────────────────────────────────────
  late bool _isActive;
  late final TextEditingController _standardFee;
  late final TextEditingController _expressFee;
  late final TextEditingController _freeOver;
  late final TextEditingController _returnPolicy;
  late final TextEditingController _responseTime;
  late final TextEditingController _shippingTime;

  // ── New delivery fields ────────────────────────────────────────────────────
  List<Map<String, String>> _areas = [];
  List<Map<String, dynamic>> _hours = [];
  bool _localCourier = true;
  bool _expressDelivery = true;
  bool _storePickup = true;
  List<Map<String, String>> _steps = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _isActive = s['isActive'] != false;

    final delivery = s['deliveryInfo'] as Map<String, dynamic>? ?? {};
    _standardFee =
        TextEditingController(text: (delivery['standardFee'] ?? 15).toString());
    _expressFee =
        TextEditingController(text: (delivery['expressFee'] ?? 25).toString());
    _freeOver = TextEditingController(
        text: (delivery['freeDeliveryOver'] ?? 150).toString());
    _returnPolicy =
        TextEditingController(text: s['returnPolicy']?.toString() ?? '');
    _responseTime =
        TextEditingController(text: s['responseTime']?.toString() ?? '< 1h');
    _shippingTime =
        TextEditingController(text: s['shippingTime']?.toString() ?? '1–2d');

    // Delivery areas
    final rawAreas = delivery['areas'];
    if (rawAreas is List && rawAreas.isNotEmpty) {
      _areas = rawAreas
          .map<Map<String, String>>((e) => {
                'name': (e['name'] ?? '').toString(),
                'time': (e['time'] ?? '').toString(),
              })
          .toList();
    } else {
      _areas = [
        {'name': 'Nablus', 'time': 'Same day'},
        {'name': 'Ramallah', 'time': '1–2 days'},
        {'name': 'Jenin', 'time': '1–2 days'},
        {'name': 'Jerusalem', 'time': '2–3 days'},
      ];
    }

    // Working hours
    final rawHours = delivery['workingHours'];
    if (rawHours is List && rawHours.isNotEmpty) {
      _hours = rawHours
          .map<Map<String, dynamic>>((e) => {
                'day': (e['day'] ?? '').toString(),
                'hours': (e['hours'] ?? '').toString(),
                'isOpen': e['isOpen'] != false,
              })
          .toList();
    } else {
      _hours = [
        {
          'day': 'Sunday – Thursday',
          'hours': '10:00 AM – 8:00 PM',
          'isOpen': true
        },
        {'day': 'Saturday', 'hours': '11:00 AM – 6:00 PM', 'isOpen': true},
        {'day': 'Friday', 'hours': 'Closed', 'isOpen': false},
      ];
    }

    // Delivery methods
    final methods = delivery['methods'] as Map<String, dynamic>? ?? {};
    _localCourier = methods['localCourier'] != false;
    _expressDelivery = methods['expressDelivery'] != false;
    _storePickup = methods['storePickup'] != false;

    // Delivery steps
    final rawSteps = delivery['deliverySteps'];
    if (rawSteps is List && rawSteps.isNotEmpty) {
      _steps = rawSteps
          .map<Map<String, String>>((e) => {
                'title': (e['title'] ?? '').toString(),
                'subtitle': (e['subtitle'] ?? '').toString(),
                'icon': (e['icon'] ?? 'local_shipping').toString(),
              })
          .toList();
    } else {
      _steps = [
        {
          'title': 'Place Your Order',
          'subtitle': 'Choose your products and complete checkout.',
          'icon': 'shopping_bag'
        },
        {
          'title': 'Store Confirms',
          'subtitle': 'The store reviews and confirms your order.',
          'icon': 'verified'
        },
        {
          'title': 'Products Prepared',
          'subtitle': 'Your skincare products are packed safely.',
          'icon': 'inventory'
        },
        {
          'title': 'Delivered to You',
          'subtitle': 'The courier delivers your order to your address.',
          'icon': 'local_shipping'
        },
      ];
    }
  }

  @override
  void dispose() {
    _standardFee.dispose();
    _expressFee.dispose();
    _freeOver.dispose();
    _returnPolicy.dispose();
    _responseTime.dispose();
    _shippingTime.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ApiService.updateStoreSettings(
      storeId: widget.storeId,
      data: {
        'isActive': _isActive,
        'returnPolicy': _returnPolicy.text.trim(),
        'responseTime': _responseTime.text.trim(),
        'shippingTime': _shippingTime.text.trim(),
        'deliveryInfo.standardFee':
            double.tryParse(_standardFee.text.trim()) ?? 15,
        'deliveryInfo.expressFee':
            double.tryParse(_expressFee.text.trim()) ?? 25,
        'deliveryInfo.freeDeliveryOver':
            double.tryParse(_freeOver.text.trim()) ?? 150,
        'deliveryInfo.areas': _areas,
        'deliveryInfo.workingHours': _hours,
        'deliveryInfo.methods': {
          'localCourier': _localCourier,
          'expressDelivery': _expressDelivery,
          'storePickup': _storePickup,
        },
        'deliveryInfo.deliverySteps': _steps,
      },
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Settings saved!'),
          backgroundColor: Color(0xFF4CAF50)));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('Failed to save settings. Try again.')));
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: deepPlum, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Store Settings',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: deepPlum)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text('Save',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: wine)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildFeesCard(),
            const SizedBox(height: 16),
            _buildAreasCard(),
            const SizedBox(height: 16),
            _buildHoursCard(),
            const SizedBox(height: 16),
            _buildMethodsCard(),
            const SizedBox(height: 16),
            _buildStepsCard(),
            const SizedBox(height: 16),
            _buildCard(title: 'Response & Shipping Time', children: [
              _textField(
                  ctrl: _responseTime,
                  label: 'Typical Response Time',
                  icon: Icons.access_time_rounded,
                  hint: 'e.g. < 1h, 2–4h'),
              const SizedBox(height: 12),
              _textField(
                  ctrl: _shippingTime,
                  label: 'Estimated Shipping',
                  icon: Icons.local_shipping_outlined,
                  hint: 'e.g. 1–2d, Same day'),
            ]),
            const SizedBox(height: 16),
            _buildCard(title: 'Return Policy', children: [
              _textField(
                  ctrl: _returnPolicy,
                  label: 'Return Policy',
                  icon: Icons.assignment_return_outlined,
                  hint: 'Describe your return and refund policy…',
                  maxLines: 4),
            ]),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Save Settings',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Store Status ───────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    return _buildCard(title: 'Store Status', children: [
      Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                (_isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                    .withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _isActive
                ? Icons.store_rounded
                : Icons.store_mall_directory_outlined,
            color:
                _isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Store is ${_isActive ? 'Open' : 'Closed'}',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
            Text(
                _isActive
                    ? 'Customers can browse and order'
                    : 'Store is hidden from customers',
                style: GoogleFonts.poppins(fontSize: 11, color: grey)),
          ]),
        ),
        Switch.adaptive(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: wine),
      ]),
    ]);
  }

  // ── Delivery fees ──────────────────────────────────────────────────────────

  Widget _buildFeesCard() {
    return _buildCard(title: 'Delivery Fees (ILS)', children: [
      _feeRow('Standard Delivery', _standardFee),
      const SizedBox(height: 12),
      _feeRow('Express Delivery', _expressFee),
      const SizedBox(height: 12),
      _feeRow('Free Delivery Over', _freeOver, hint: '0 to disable'),
    ]);
  }

  // ── Delivery areas ─────────────────────────────────────────────────────────

  Widget _buildAreasCard() {
    return _buildCard(
      title: 'Delivery Areas',
      trailing: GestureDetector(
        onTap: () => _showAreaSheet(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: wine.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 14, color: wine),
            const SizedBox(width: 3),
            Text('Add',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: wine, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      children: [
        if (_areas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No delivery areas added.',
                style: GoogleFonts.poppins(fontSize: 12, color: grey)),
          ),
        ..._areas.asMap().entries.map((entry) {
          final i = entry.key;
          final area = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, size: 15, color: wine),
              const SizedBox(width: 8),
              Expanded(
                child: Text(area['name'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkText,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(area['time'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 11, color: wine)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAreaSheet(editIndex: i),
                child: const Icon(Icons.edit_outlined,
                    size: 15, color: Color(0xFF7A7A7A)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _areas.removeAt(i)),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFF44336)),
              ),
            ]),
          );
        }),
      ],
    );
  }

  void _showAreaSheet({int? editIndex}) {
    final nameCtrl = TextEditingController(
        text: editIndex != null ? _areas[editIndex]['name'] : '');
    final timeCtrl = TextEditingController(
        text: editIndex != null ? _areas[editIndex]['time'] : '1–2 days');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editIndex != null ? 'Edit Area' : 'Add Delivery Area',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkText)),
              const SizedBox(height: 16),
              _sheetField(
                  nameCtrl, 'City / Area Name', Icons.location_city_outlined),
              const SizedBox(height: 12),
              _sheetField(timeCtrl, 'Delivery Time (e.g. 1–2 days)',
                  Icons.schedule_outlined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    setState(() {
                      if (editIndex != null) {
                        _areas[editIndex] = {
                          'name': name,
                          'time': timeCtrl.text.trim()
                        };
                      } else {
                        _areas
                            .add({'name': name, 'time': timeCtrl.text.trim()});
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(editIndex != null ? 'Update' : 'Add Area',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Working hours ──────────────────────────────────────────────────────────

  Widget _buildHoursCard() {
    return _buildCard(
      title: 'Working Hours',
      trailing: GestureDetector(
        onTap: () => _showHoursSheet(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 14, color: wine),
            const SizedBox(width: 3),
            Text('Add',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: wine, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      children: [
        if (_hours.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No hours added.',
                style: GoogleFonts.poppins(fontSize: 12, color: grey)),
          ),
        ..._hours.asMap().entries.map((entry) {
          final i = entry.key;
          final h = entry.value;
          final isOpen = h['isOpen'] as bool? ?? true;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
                color: softBg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['day']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText)),
                      Text(isOpen ? (h['hours']?.toString() ?? '') : 'Closed',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isOpen ? grey : const Color(0xFFF44336))),
                    ]),
              ),
              Switch.adaptive(
                value: isOpen,
                onChanged: (v) => setState(() => _hours[i]['isOpen'] = v),
                activeColor: wine,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showHoursSheet(editIndex: i),
                child: const Icon(Icons.edit_outlined,
                    size: 15, color: Color(0xFF7A7A7A)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _hours.removeAt(i)),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFF44336)),
              ),
            ]),
          );
        }),
      ],
    );
  }

  void _showHoursSheet({int? editIndex}) {
    final dayCtrl = TextEditingController(
        text: editIndex != null ? _hours[editIndex]['day'].toString() : '');
    final hoursCtrl = TextEditingController(
        text: editIndex != null
            ? _hours[editIndex]['hours'].toString()
            : '10:00 AM – 8:00 PM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  editIndex != null
                      ? 'Edit Working Hours'
                      : 'Add Working Hours',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkText)),
              const SizedBox(height: 16),
              _sheetField(dayCtrl, 'Day (e.g. Sunday – Thursday)',
                  Icons.calendar_today_outlined),
              const SizedBox(height: 12),
              _sheetField(hoursCtrl, 'Hours (e.g. 10:00 AM – 8:00 PM)',
                  Icons.access_time_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final day = dayCtrl.text.trim();
                    if (day.isEmpty) return;
                    setState(() {
                      if (editIndex != null) {
                        _hours[editIndex]['day'] = day;
                        _hours[editIndex]['hours'] = hoursCtrl.text.trim();
                      } else {
                        _hours.add({
                          'day': day,
                          'hours': hoursCtrl.text.trim(),
                          'isOpen': true
                        });
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(editIndex != null ? 'Update' : 'Add Hours',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delivery methods ───────────────────────────────────────────────────────

  Widget _buildMethodsCard() {
    return _buildCard(title: 'Delivery Methods', children: [
      _methodToggle(
        icon: Icons.local_shipping_outlined,
        label: 'Local Courier',
        sub: 'Standard delivery via courier',
        value: _localCourier,
        onChanged: (v) => setState(() => _localCourier = v),
      ),
      const SizedBox(height: 4),
      _methodToggle(
        icon: Icons.flash_on_outlined,
        label: 'Express Delivery',
        sub: 'Same-day or next-day delivery',
        value: _expressDelivery,
        onChanged: (v) => setState(() => _expressDelivery = v),
      ),
      const SizedBox(height: 4),
      _methodToggle(
        icon: Icons.store_outlined,
        label: 'Store Pickup',
        sub: 'Customer collects from your store',
        value: _storePickup,
        onChanged: (v) => setState(() => _storePickup = v),
      ),
    ]);
  }

  Widget _methodToggle({
    required IconData icon,
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (value ? wine : grey).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: value ? wine : grey),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
          Text(sub, style: GoogleFonts.poppins(fontSize: 10.5, color: grey)),
        ]),
      ),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: wine),
    ]);
  }

  // ── Delivery steps / order process ─────────────────────────────────────────

  Widget _buildStepsCard() {
    return _buildCard(
      title: 'Order Process Steps',
      trailing: GestureDetector(
        onTap: () => _showStepSheet(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 14, color: wine),
            const SizedBox(width: 3),
            Text('Add',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: wine, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      children: [
        if (_steps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No steps added.',
                style: GoogleFonts.poppins(fontSize: 12, color: grey)),
          ),
        ..._steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
                color: softBg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: wine.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text('${i + 1}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: wine)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['title'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText)),
                      if ((step['subtitle'] ?? '').isNotEmpty)
                        Text(step['subtitle']!,
                            style:
                                GoogleFonts.poppins(fontSize: 11, color: grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
              ),
              GestureDetector(
                onTap: () => _showStepSheet(editIndex: i),
                child: const Icon(Icons.edit_outlined,
                    size: 15, color: Color(0xFF7A7A7A)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _steps.removeAt(i)),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFF44336)),
              ),
            ]),
          );
        }),
      ],
    );
  }

  void _showStepSheet({int? editIndex}) {
    final titleCtrl = TextEditingController(
        text: editIndex != null ? _steps[editIndex]['title'] : '');
    final subtitleCtrl = TextEditingController(
        text: editIndex != null ? _steps[editIndex]['subtitle'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editIndex != null ? 'Edit Step' : 'Add Order Step',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkText)),
              const SizedBox(height: 16),
              _sheetField(titleCtrl, 'Step Title', Icons.title_rounded),
              const SizedBox(height: 12),
              _sheetField(
                  subtitleCtrl, 'Step Description', Icons.notes_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    setState(() {
                      if (editIndex != null) {
                        _steps[editIndex] = {
                          'title': title,
                          'subtitle': subtitleCtrl.text.trim(),
                          'icon': _steps[editIndex]['icon'] ?? 'local_shipping',
                        };
                      } else {
                        _steps.add({
                          'title': title,
                          'subtitle': subtitleCtrl.text.trim(),
                          'icon': 'local_shipping',
                        });
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(editIndex != null ? 'Update' : 'Add Step',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared card/field helpers ──────────────────────────────────────────────

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: grey)),
            const Spacer(),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _feeRow(String label, TextEditingController ctrl, {String? hint}) {
    return Row(children: [
      Expanded(
        child: Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: darkText)),
      ),
      SizedBox(
        width: 100,
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
          decoration: InputDecoration(
            hintText: hint ?? '0',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
            filled: true,
            fillColor: softBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
      ),
    ]);
  }

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: grey.withOpacity(0.6)),
        prefixIcon: Icon(icon, size: 18, color: grey),
        filled: true,
        fillColor: softBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: wine, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.poppins(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
        prefixIcon: Icon(icon, size: 18, color: grey),
        filled: true,
        fillColor: softBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: wine, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
