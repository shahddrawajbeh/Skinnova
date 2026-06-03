import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List _users = [];
  int _total = 0;
  String _adminId = '';
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showUserDetails(Map user) {
    final imageUrl = (user['profileImage'] ?? '').toString();
    final onboarding = user['onboarding'] as Map? ?? {};
    final scanPrivacy = user['scanPrivacy'] as Map? ?? {};

    String listText(dynamic value) {
      if (value is List) {
        return value.isEmpty ? 'N/A' : value.join(', ');
      }
      return value?.toString().isNotEmpty == true ? value.toString() : 'N/A';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "User Details",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AdminTheme.black,
          ),
        ),
        content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: AdminTheme.wineMuted,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? Text(
                            (user['fullName'] ?? 'U')
                                .toString()[0]
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.wine,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow("Name", user['fullName'] ?? 'N/A'),
                _detailRow("Email", user['email'] ?? 'N/A'),
                _detailRow("Status",
                    user['isActive'] == false ? 'Inactive' : 'Active'),
                _detailRow("City", user['city'] ?? 'N/A'),
                _detailRow("Bio", user['bio'] ?? 'N/A'),
                const Divider(height: 24),
                _detailRow("Gender", onboarding['gender'] ?? 'N/A'),
                _detailRow("Age Range", onboarding['ageRange'] ?? 'N/A'),
                _detailRow("Skin Type", onboarding['skinType'] ?? 'N/A'),
                _detailRow(
                    "Sensitivity", onboarding['skinSensitivity'] ?? 'N/A'),
                _detailRow("Concerns", listText(onboarding['skinConcerns'])),
                _detailRow("Phototype", onboarding['skinPhototype'] ?? 'N/A'),
                _detailRow(
                    "Experience", onboarding['skincareExperience'] ?? 'N/A'),
                _detailRow("Goals", listText(onboarding['goals'])),
                _detailRow("Chronic Condition",
                    onboarding['chronicCondition'] ?? 'N/A'),
                _detailRow("Special Conditions",
                    listText(onboarding['specialConditions'])),
                const Divider(height: 24),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Close",
              style: GoogleFonts.poppins(color: AdminTheme.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 125,
              child: Text(
                "$label:",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AdminTheme.grey,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? "N/A" : value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AdminTheme.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetUsers(
        _adminId,
        search: _searchCtrl.text.trim(),
        role: _roleFilter,
      );

      final allUsers = data['users'] as List? ?? [];

      final filteredUsers = allUsers.where((u) {
        final role = ((u as Map)['role'] ?? 'user').toString();
        return role == 'user';
      }).toList();

      if (!mounted) return;
      setState(() {
        _users = filteredUsers;
        _total = filteredUsers.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _topBar(),
      Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _users.isEmpty
                  ? _emptyState()
                  : _buildList()),
    ]);
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        color: AdminTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Users", style: AdminTheme.title(20)),
                const SizedBox(width: 10),
                _badge(_total),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _load(),
                    decoration: _inputDec("Search users...").copyWith(
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AdminTheme.grey,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  // Widget _topBar() => Container(
  //       padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
  //       color: AdminTheme.card,
  //       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //         Row(children: [
  //           Text("Users", style: AdminTheme.title(20)),
  //           const SizedBox(width: 10),
  //           _badge(_total),
  //           const Spacer(),
  //           _wineBtn("Add User", Icons.add, () => _showEditDialog()),
  //         ]),
  //         const SizedBox(height: 12),
  //         Row(children: [
  //           Expanded(
  //               child: TextField(
  //             controller: _searchCtrl,
  //             onSubmitted: (_) => _load(),
  //             decoration: _inputDec("Search users...").copyWith(
  //                 prefixIcon: const Icon(Icons.search,
  //                     size: 18, color: AdminTheme.grey)),
  //             style: GoogleFonts.poppins(fontSize: 13),
  //           )),
  //           const SizedBox(width: 10),
  //           DropdownButtonHideUnderline(
  //               child: DropdownButton<String>(
  //             value: _roleFilter.isEmpty ? null : _roleFilter,
  //             hint: Text("All Roles",
  //                 style: GoogleFonts.poppins(
  //                     fontSize: 13, color: AdminTheme.grey)),
  //             borderRadius: BorderRadius.circular(12),
  //             items: ['', 'user', 'seller', 'admin']
  //                 .map((r) => DropdownMenuItem(
  //                     value: r,
  //                     child: Text(r.isEmpty ? 'All' : r,
  //                         style: GoogleFonts.poppins(fontSize: 13))))
  //                 .toList(),
  //             onChanged: (v) {
  //               setState(() => _roleFilter = v ?? '');
  //               _load();
  //             },
  //           )),
  //         ]),
  //       ]),
  //     );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i] as Map;
          final imageUrl = (u['profileImage'] ??
                  u['avatar'] ??
                  u['storeLogo'] ??
                  u['logoUrl'] ??
                  '')
              .toString();

          final hasImage = imageUrl.isNotEmpty;
          final isActive = u['isActive'] != false;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AdminTheme.cardDec(),
            child: Row(children: [
              CircleAvatar(
                  radius: 20,
                  backgroundColor: AdminTheme.wineMuted,
                  backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                  child: !hasImage
                      ? Text((u['fullName'] ?? 'U').toString()[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.wine))
                      : null),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(u['fullName'] ?? '',
                        style: AdminTheme.title(13.5, w: FontWeight.w500)),
                    Text(u['email'] ?? '', style: AdminTheme.sub(12)),
                  ])),
              _rolePill(u['role'] ?? 'user'),
              const SizedBox(width: 8),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade400
                          : Colors.red.shade300,
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AdminTheme.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) async {
                  if (v == 'details') _showUserDetails(u);

                  if (v == 'toggle') {
                    await ApiService.adminToggleUserActive(_adminId, u['_id']);
                    _load();
                  }

                  if (v == 'delete') {
                    if (await _confirm("Delete this user permanently?")) {
                      await ApiService.adminDeleteUser(_adminId, u['_id']);
                      _showSnack("User deleted");
                      _load();
                    }
                  }
                },
                itemBuilder: (_) => [
                  _popItem('details', 'View Details', Icons.info_outline),
                  _popItem(
                    'toggle',
                    isActive ? 'Deactivate' : 'Activate',
                    isActive
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                  ),
                  _popItem(
                    'delete',
                    'Delete',
                    Icons.delete_outline,
                    danger: true,
                  ),
                ],
              ),
            ]),
          );
        },
      );

  Widget _rolePill(String role) {
    Color c = role == 'admin' ? Colors.red.shade400 : AdminTheme.wine;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

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
        Icon(Icons.people_outline,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No users found", style: AdminTheme.sub(15)),
      ]));

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  TextField _f(String label, TextEditingController ctrl,
          {bool obscure = false}) =>
      TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: _inputDec(label),
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
                      child: Text("Confirm",
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
