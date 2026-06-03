import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminAdminsScreen extends StatefulWidget {
  const AdminAdminsScreen({super.key});
  @override
  State<AdminAdminsScreen> createState() => _AdminAdminsScreenState();
}

class _AdminAdminsScreenState extends State<AdminAdminsScreen> {
  bool _loading = true;
  List _admins = [];
  String _adminId = '';

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
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetAdmins(_adminId);
      if (!mounted) return;
      setState(() {
        _admins = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add Admin Account",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AdminTheme.black)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field("Full Name", nameCtrl),
          const SizedBox(height: 10),
          _field("Email", emailCtrl),
          const SizedBox(height: 10),
          _field("Password", passCtrl, obscure: true),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel",
                  style: GoogleFonts.poppins(color: AdminTheme.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.wine,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.adminCreateAdmin(_adminId, {
                  'fullName': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'password': passCtrl.text,
                });
                _showSnack("Admin created");
                _load();
              } catch (e) {
                _showSnack(e.toString(), error: true);
              }
            },
            child:
                Text("Create", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(Map admin) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Change Password",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AdminTheme.black)),
        content: _field("New Password", passCtrl, obscure: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel",
                  style: GoogleFonts.poppins(color: AdminTheme.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.wine,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ApiService.adminChangeAdminPassword(
                  _adminId, admin['_id'], passCtrl.text);
              if (ok) _showSnack("Password changed");
            },
            child:
                Text("Save", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _admins.isEmpty
                  ? _emptyState()
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        color: AdminTheme.card,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      "Admin Accounts",
                      overflow: TextOverflow.ellipsis,
                      style: AdminTheme.title(18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _badge(_admins.length),
                ],
              ),
            ),
            IconButton(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AdminTheme.wine,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _admins.length,
        itemBuilder: (_, i) {
          final a = _admins[i] as Map;
          final isSelf = a['_id'] == _adminId;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AdminTheme.cardDec(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AdminTheme.wineMuted,
                  child: Text(
                      (a['fullName'] ?? 'A').toString()[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, color: AdminTheme.wine)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(a['fullName'] ?? '',
                              style:
                                  AdminTheme.title(13.5, w: FontWeight.w500)),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AdminTheme.wineMuted,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text("You",
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AdminTheme.wine,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ]),
                        Text(a['email'] ?? '', style: AdminTheme.sub(12)),
                      ]),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: AdminTheme.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) async {
                    if (v == 'password') _showPasswordDialog(a);
                    if (v == 'delete' && !isSelf) {
                      if (await _confirm("Delete this admin account?")) {
                        await ApiService.adminDeleteAdmin(_adminId, a['_id']);
                        _showSnack("Admin deleted");
                        _load();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    _popItem('password', 'Change Password', Icons.lock_outline),
                    if (!isSelf)
                      _popItem('delete', 'Delete', Icons.delete_outline,
                          danger: true),
                  ],
                ),
              ],
            ),
          );
        },
      );

  PopupMenuItem<String> _popItem(String v, String l, IconData i,
          {bool danger = false}) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(i,
                size: 16,
                color: danger ? Colors.red.shade400 : AdminTheme.grey),
            const SizedBox(width: 8),
            Text(l,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: danger ? Colors.red.shade400 : AdminTheme.black)),
          ]));

  Widget _badge(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: AdminTheme.wineMuted,
            borderRadius: BorderRadius.circular(20)),
        child: Text("$n",
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: AdminTheme.wine,
                fontWeight: FontWeight.w600)),
      );

  Widget _wineBtn(String label, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: Colors.white),
        label: Text(label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.wine,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.admin_panel_settings_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No admin accounts", style: AdminTheme.sub(15)),
      ]));

  TextField _field(String label, TextEditingController ctrl,
          {bool obscure = false}) =>
      TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
          style: GoogleFonts.poppins(fontSize: 13));

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text("Confirm",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: AdminTheme.black)),
                content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Cancel",
                          style: GoogleFonts.poppins(color: AdminTheme.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("Delete",
                          style: GoogleFonts.poppins(color: Colors.white))),
                ],
              )) ??
      false;

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
