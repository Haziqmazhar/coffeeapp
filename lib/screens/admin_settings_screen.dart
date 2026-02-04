import 'package:flutter/material.dart';

import '../data/supabase_client.dart';
import '../theme/coffee_palette.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late Future<List<_StaffPermissionRow>> _permissionsFuture;
  late Future<List<_ReviewRow>> _reviewsFuture;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _savingProfile = false;
  bool _savingPermissions = false;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _fetchStaffPermissions();
    _reviewsFuture = _fetchReviews();
    _loadAccount();
  }

  Future<void> _refresh() async {
    final permissions = await _fetchStaffPermissions();
    final reviews = await _fetchReviews();
    if (!mounted) return;
    setState(() {
      _permissionsFuture = Future.value(permissions);
      _reviewsFuture = Future.value(reviews);
    });
  }

  Future<void> _loadAccount() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;
    final row = await supabase
        .from('users')
        .select('name,email,phone')
        .eq('auth_user_id', session.user.id)
        .maybeSingle();
    if (!mounted) return;
    _nameController.text = (row?['name'] as String?) ?? '';
    _emailController.text = (row?['email'] as String?) ?? '';
    _phoneController.text = (row?['phone'] as String?) ?? '';
    setState(() {});
  }

  Future<void> _saveAccount() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;
    setState(() => _savingProfile = true);
    await supabase.from('users').upsert({
      'auth_user_id': session.user.id,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, onConflict: 'auth_user_id');
    if (!mounted) return;
    setState(() => _savingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account settings updated.')),
    );
  }

  Future<List<_ReviewRow>> _fetchReviews() async {
    final response = await supabase
        .from('reviews')
        .select('id,rating,comment,created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List<dynamic>)
        .map((row) => _ReviewRow.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> _deleteReview(String id) async {
    await supabase.from('reviews').delete().eq('id', id);
    await _refresh();
  }

  Future<List<_StaffPermissionRow>> _fetchStaffPermissions() async {
    final staffRows = await supabase
        .from('staff_profiles')
        .select('id,auth_user_id,role,store_id');
    final userRows =
        await supabase.from('users').select('auth_user_id,name,email,avatar_url');
    final storeRows = await supabase.from('stores').select('id,name');
    final permissionRows = await supabase.from('staff_permissions').select(
        'staff_id,can_manage_menu,can_manage_orders,can_view_finance,can_manage_staff,can_view_audit');

    final storeNames = <String, String>{};
    for (final row in (storeRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final id = (map['id'] as String?) ?? '';
      final name = (map['name'] as String?) ?? '';
      if (id.isNotEmpty) {
        storeNames[id] = name;
      }
    }

    final usersByAuth = <String, Map<String, dynamic>>{};
    for (final row in (userRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final id = (map['auth_user_id'] as String?) ?? '';
      if (id.isNotEmpty) {
        usersByAuth[id] = map;
      }
    }

    final permsByStaff = <String, Map<String, dynamic>>{};
    for (final row in (permissionRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final id = (map['staff_id'] as String?) ?? '';
      if (id.isNotEmpty) {
        permsByStaff[id] = map;
      }
    }

    return (staffRows as List<dynamic>).map((row) {
      final map = row as Map<String, dynamic>;
      final staffId = (map['id'] as String?) ?? '';
      final authId = (map['auth_user_id'] as String?) ?? '';
      final user = usersByAuth[authId] ?? {};
      final perms = permsByStaff[staffId] ?? {};
      return _StaffPermissionRow(
        staffId: staffId,
        authUserId: authId,
        name: (user['name'] as String?) ?? 'Staff',
        email: (user['email'] as String?) ?? '',
        avatarUrl: (user['avatar_url'] as String?) ?? '',
        role: (map['role'] as String?) ?? 'staff',
        storeName:
            storeNames[(map['store_id'] as String?) ?? ''] ?? 'Unassigned',
        canManageMenu: (perms['can_manage_menu'] as bool?) ?? false,
        canManageOrders: (perms['can_manage_orders'] as bool?) ?? false,
        canViewFinance: (perms['can_view_finance'] as bool?) ?? false,
        canManageStaff: (perms['can_manage_staff'] as bool?) ?? false,
        canViewAudit: (perms['can_view_audit'] as bool?) ?? false,
      );
    }).toList();
  }

  Future<void> _updatePermission(
    _StaffPermissionRow row, {
    bool? canManageMenu,
    bool? canManageOrders,
    bool? canViewFinance,
    bool? canManageStaff,
    bool? canViewAudit,
  }) async {
    setState(() => _savingPermissions = true);
    await supabase.from('staff_permissions').upsert({
      'staff_id': row.staffId,
      'can_manage_menu': canManageMenu ?? row.canManageMenu,
      'can_manage_orders': canManageOrders ?? row.canManageOrders,
      'can_view_finance': canViewFinance ?? row.canViewFinance,
      'can_manage_staff': canManageStaff ?? row.canManageStaff,
      'can_view_audit': canViewAudit ?? row.canViewAudit,
    }, onConflict: 'staff_id');
    await _refresh();
    if (!mounted) return;
    setState(() => _savingPermissions = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            color: CoffeePalette.espresso,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          _SectionCard(
            title: 'Account Settings',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    fillColor: CoffeePalette.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: CoffeePalette.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    filled: true,
                    fillColor: CoffeePalette.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingProfile ? null : _saveAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoffeePalette.espresso,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(_savingProfile ? 'Saving...' : 'Save changes'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Permissions',
            child: FutureBuilder<List<_StaffPermissionRow>>(
              future: _permissionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final staff = snapshot.data ?? [];
                if (staff.isEmpty) {
                  return Text(
                    'No staff profiles found.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: staff.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CoffeePalette.cream,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: CoffeePalette.caramelSoft,
                                  backgroundImage: row.avatarUrl.trim().isEmpty
                                      ? null
                                      : NetworkImage(row.avatarUrl.trim()),
                                  child: row.avatarUrl.trim().isEmpty
                                      ? const Icon(Icons.person,
                                          color: CoffeePalette.espresso)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(row.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(
                                        '${row.email} • ${row.storeName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _PermissionToggle(
                              label: 'Manage menu',
                              value: row.canManageMenu,
                              onChanged: _savingPermissions
                                  ? null
                                  : (value) => _updatePermission(
                                        row,
                                        canManageMenu: value,
                                      ),
                            ),
                            _PermissionToggle(
                              label: 'Manage orders',
                              value: row.canManageOrders,
                              onChanged: _savingPermissions
                                  ? null
                                  : (value) => _updatePermission(
                                        row,
                                        canManageOrders: value,
                                      ),
                            ),
                            _PermissionToggle(
                              label: 'View finance',
                              value: row.canViewFinance,
                              onChanged: _savingPermissions
                                  ? null
                                  : (value) => _updatePermission(
                                        row,
                                        canViewFinance: value,
                                      ),
                            ),
                            _PermissionToggle(
                              label: 'Manage staff',
                              value: row.canManageStaff,
                              onChanged: _savingPermissions
                                  ? null
                                  : (value) => _updatePermission(
                                        row,
                                        canManageStaff: value,
                                      ),
                            ),
                            _PermissionToggle(
                              label: 'View audit',
                              value: row.canViewAudit,
                              onChanged: _savingPermissions
                                  ? null
                                  : (value) => _updatePermission(
                                        row,
                                        canViewAudit: value,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Review Management',
            child: FutureBuilder<List<_ReviewRow>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return Text(
                    'No reviews yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: reviews.map((review) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: CoffeePalette.caramelSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${review.rating}/5',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.comment.isEmpty
                                      ? 'No comment'
                                      : review.comment,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  review.timeLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteReview(review.id),
                            icon: const Icon(Icons.delete_outline),
                            color: CoffeePalette.espresso,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReviewRow {
  const _ReviewRow({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory _ReviewRow.fromMap(Map<String, dynamic> data) {
    return _ReviewRow(
      id: (data['id'] as String?) ?? '',
      rating: (data['rating'] as int?) ?? 0,
      comment: (data['comment'] as String?) ?? '',
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get timeLabel {
    final local = createdAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StaffPermissionRow {
  const _StaffPermissionRow({
    required this.staffId,
    required this.authUserId,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.storeName,
    required this.canManageMenu,
    required this.canManageOrders,
    required this.canViewFinance,
    required this.canManageStaff,
    required this.canViewAudit,
  });

  final String staffId;
  final String authUserId;
  final String name;
  final String email;
  final String avatarUrl;
  final String role;
  final String storeName;
  final bool canManageMenu;
  final bool canManageOrders;
  final bool canViewFinance;
  final bool canManageStaff;
  final bool canViewAudit;
}

class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: CoffeePalette.espresso,
        ),
      ],
    );
  }
}
