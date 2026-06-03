import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'seller_home_screen.dart';

class StoreRequestScreen extends StatefulWidget {
  const StoreRequestScreen({super.key});

  @override
  State<StoreRequestScreen> createState() => _StoreRequestScreenState();
}

class _StoreRequestScreenState extends State<StoreRequestScreen> {
  // ── Skinova palette ────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color wineMuted = Color(0xFFF2E8EA);
  static const Color bg = Color(0xFFF7F4F3);
  static const Color card = Colors.white;
  static const Color black = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _submitting = false;
  String _userId = '';
  Map<String, dynamic>? _existingStore;

  // Form controllers
  final _storeNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  File? _logoFile;
  File? _coverFile;
  File? _docFile;
  String _logoUrl = '';
  String _coverUrl = '';
  String _docUrl = '';
  String _docType = 'business_license';

  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  static const List<String> _docTypes = [
    'business_license',
    'cosmetics_permit',
    'pharmacy_license',
    'id_proof',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    await _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    setState(() => _loading = true);
    try {
      final store = await ApiService.getMyStoreRequest(_userId);
      if (!mounted) return;
      setState(() {
        _existingStore = store;
        _loading = false;
      });
    } catch (_) {
      // 404 = no request yet
      if (!mounted) return;
      setState(() {
        _existingStore = null;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage(String field) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;
    setState(() {
      if (field == 'logo') _logoFile = File(picked.path);
      if (field == 'cover') _coverFile = File(picked.path);
    });
  }

  Future<void> _pickDocument() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() => _docFile = File(picked.path));
  }

  Future<String?> _uploadImage(File file) async {
    return await ApiService.uploadStoreImage(file);
  }

  Future<String?> _uploadDocument(File file) async {
    return await ApiService.uploadVerificationDocument(file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      // Upload images first if selected
      if (_logoFile != null) {
        _logoUrl = await _uploadImage(_logoFile!) ?? '';
      }
      if (_coverFile != null) {
        _coverUrl = await _uploadImage(_coverFile!) ?? '';
      }
      if (_docFile != null) {
        _docUrl = await _uploadDocument(_docFile!) ?? '';
      }

      await ApiService.submitStoreRequest(
        userId: _userId,
        storeName: _storeNameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        logoUrl: _logoUrl,
        coverImageUrl: _coverUrl,
        verificationDocumentUrl: _docUrl,
        verificationDocumentType: _docType,
      );

      if (!mounted) return;
      _showSnack("Store request submitted! We'll review it shortly.");
      await _checkExistingRequest();
    } catch (e) {
      if (!mounted) return;
      _showSnack("Failed to submit: $e", error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      if (_logoFile != null) _logoUrl = await _uploadImage(_logoFile!) ?? '';
      if (_coverFile != null) _coverUrl = await _uploadImage(_coverFile!) ?? '';
      if (_docFile != null) _docUrl = await _uploadDocument(_docFile!) ?? '';

      final storeId = _existingStore!['_id'].toString();
      await ApiService.resubmitStoreRequest(
        storeId: storeId,
        storeName: _storeNameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        logoUrl:
            _logoUrl.isNotEmpty ? _logoUrl : (_existingStore!['logoUrl'] ?? ''),
        coverImageUrl: _coverUrl.isNotEmpty
            ? _coverUrl
            : (_existingStore!['coverImageUrl'] ?? ''),
        verificationDocumentUrl: _docUrl.isNotEmpty
            ? _docUrl
            : (_existingStore!['verificationDocumentUrl'] ?? ''),
        verificationDocumentType: _docType,
      );

      if (!mounted) return;
      _showSnack("Request resubmitted successfully!");
      await _checkExistingRequest();
    } catch (e) {
      if (!mounted) return;
      _showSnack("Failed to resubmit: $e", error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _prefillFromStore() {
    if (_existingStore == null) return;
    _storeNameCtrl.text = _existingStore!['storeName'] ?? '';
    _cityCtrl.text = _existingStore!['city'] ?? '';
    _addressCtrl.text = _existingStore!['address'] ?? '';
    _phoneCtrl.text = _existingStore!['phone'] ?? '';
    _descCtrl.text = _existingStore!['description'] ?? '';
    _logoUrl = _existingStore!['logoUrl'] ?? '';
    _coverUrl = _existingStore!['coverImageUrl'] ?? '';
    _docUrl = _existingStore!['verificationDocumentUrl'] ?? '';
    _docType =
        _existingStore!['verificationDocumentType'] ?? 'business_license';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        foregroundColor: black,
        elevation: 0,
        title: Text("Open a Store",
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: black)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: line, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_existingStore == null) return _buildForm(isResubmit: false);

    final status = _existingStore!['approvalStatus'] ?? 'pending';

    switch (status) {
      case 'pending':
        return _buildStatusScreen(
          icon: Icons.hourglass_empty_rounded,
          iconColor: Colors.orange.shade600,
          title: "Under Review",
          subtitle:
              "Your store request has been submitted and is being reviewed by our team. We'll notify you once it's approved.",
          storeName: _existingStore!['storeName'] ?? '',
          actions: [],
        );

      case 'approved':
        return _buildStatusScreen(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green.shade600,
          title: "Store Approved!",
          subtitle:
              "Your store has been approved. You can now access your seller dashboard and start selling.",
          storeName: _existingStore!['storeName'] ?? '',
          actions: [
            _wineButton(
              "Go to Seller Dashboard",
              Icons.storefront_rounded,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const SellerHomeScreen())),
            ),
          ],
        );

      case 'rejected':
        _prefillFromStore();
        return _buildRejectedView();

      default:
        return _buildForm(isResubmit: false);
    }
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String storeName,
    required List<Widget> actions,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 48),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700, color: black)),
            const SizedBox(height: 8),
            if (storeName.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: wineMuted, borderRadius: BorderRadius.circular(20)),
                child: Text(storeName,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: wine,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: grey, height: 1.6)),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 32),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView() {
    final reason = _existingStore!['rejectionReason'] ?? 'No reason provided.';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rejection banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel_rounded,
                    color: Colors.red.shade400, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Request Rejected",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700)),
                      const SizedBox(height: 4),
                      Text("Reason: $reason",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.red.shade600,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Edit & Resubmit Your Request",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: black)),
          const SizedBox(height: 16),
          _buildForm(isResubmit: true),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isResubmit}) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isResubmit) ...[
              // Hero header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [wine, const Color(0xFF7A3146)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Become a Store Owner",
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text("Fill in your store details to get started",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Store Info ──
            _sectionLabel("Store Information"),
            _field("Store Name *", _storeNameCtrl,
                validator: (v) => v!.trim().isEmpty ? "Required" : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _field("City *", _cityCtrl,
                      validator: (v) => v!.trim().isEmpty ? "Required" : null)),
              const SizedBox(width: 12),
              Expanded(child: _field("Phone", _phoneCtrl)),
            ]),
            const SizedBox(height: 12),
            _field("Address", _addressCtrl),
            const SizedBox(height: 12),
            _field("Description", _descCtrl,
                maxLines: 3, hint: "Tell customers about your store..."),

            // ── Images ──
            const SizedBox(height: 20),
            _sectionLabel("Store Images"),
            Row(children: [
              Expanded(
                  child: _imagePickerTile(
                      "Logo", _logoFile, _logoUrl, () => _pickImage('logo'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _imagePickerTile("Cover", _coverFile, _coverUrl,
                      () => _pickImage('cover'))),
            ]),

            // ── Verification Document ──
            const SizedBox(height: 20),
            _sectionLabel("Verification Document"),
            Text(
                "Upload a business license, permit, or ID to speed up approval.",
                style: GoogleFonts.poppins(fontSize: 12.5, color: grey)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _docType,
              decoration: _inputDec("Document Type"),
              items: _docTypes
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_docTypeLabel(t),
                          style: GoogleFonts.poppins(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _docType = v!),
            ),
            const SizedBox(height: 12),
            _documentPickerTile(),

            // ── Submit ──
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _submitting ? null : (isResubmit ? _resubmit : _submit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        isResubmit
                            ? "Resubmit Request"
                            : "Submit Store Request",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: wine)),
      );

  Widget _imagePickerTile(
      String label, File? file, String existingUrl, VoidCallback onTap) {
    final hasImage = file != null || existingUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: hasImage ? null : wineMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasImage ? wine.withOpacity(0.3) : line),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
                file != null
                    ? Image.file(file, fit: BoxFit.cover)
                    : Image.network(existingUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(label)),
                Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: wine, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded,
                          size: 12, color: Colors.white),
                    )),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined, color: wine, size: 28),
                const SizedBox(height: 6),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: wine,
                        fontWeight: FontWeight.w500)),
              ]),
      ),
    );
  }

  Widget _documentPickerTile() {
    final hasDoc = _docFile != null || _docUrl.isNotEmpty;
    return GestureDetector(
      onTap: _pickDocument,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDoc ? wineMuted : const Color(0xFFFAF8F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasDoc ? wine.withOpacity(0.4) : line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasDoc ? wine : line,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasDoc ? Icons.description_rounded : Icons.upload_file_rounded,
                color: hasDoc ? Colors.white : grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDoc
                        ? (_docFile != null
                            ? "Document selected"
                            : "Document uploaded")
                        : "Tap to upload document",
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: hasDoc ? wine : black),
                  ),
                  Text(
                    hasDoc ? "Tap to change" : "JPG, PNG or PDF accepted",
                    style: GoogleFonts.poppins(fontSize: 12, color: grey),
                  ),
                ],
              ),
            ),
            if (hasDoc)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(String label) => Container(
        color: wineMuted,
        child: Center(
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 12, color: wine))),
      );

  String _docTypeLabel(String t) {
    const labels = {
      'business_license': 'Business License',
      'cosmetics_permit': 'Cosmetics Permit',
      'pharmacy_license': 'Pharmacy License',
      'id_proof': 'ID Proof',
      'other': 'Other Document',
    };
    return labels[t] ?? t;
  }

  Widget _wineButton(String label, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: wine,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  InputDecoration _inputDec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  TextFormField _field(String label, TextEditingController ctrl,
          {int maxLines = 1,
          String? hint,
          String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        validator: validator,
        decoration: _inputDec(label, hint: hint),
        style: GoogleFonts.poppins(fontSize: 13),
      );

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : wine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
