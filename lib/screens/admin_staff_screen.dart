import 'package:flutter/material.dart';

import '../data/supabase_client.dart';
import '../theme/coffee_palette.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  late Future<List<_AdminUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<void> _refresh() async {
    final users = await _loadUsers();
    if (!mounted) return;
    setState(() => _usersFuture = Future.value(users));
  }

  Future<List<_AdminUser>> _loadUsers() async {
    final usersRes = await supabase
        .from('users')
        .select('id,auth_user_id,name,email,role,avatar_url')
        .order('name');
    final staffRes = await supabase
        .from('staff_profiles')
        .select('auth_user_id,store_id');
    final storesRes = await supabase.from('stores').select('id,name');

    final storeNames = <String, String>{};
    for (final row in (storesRes as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final id = (map['id'] as String?) ?? '';
      final name = (map['name'] as String?) ?? '';
      if (id.isNotEmpty) {
        storeNames[id] = name;
      }
    }

    final staffStores = <String, String>{};
    for (final row in (staffRes as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final authUserId = (map['auth_user_id'] as String?) ?? '';
      final storeId = (map['store_id'] as String?) ?? '';
      if (authUserId.isNotEmpty) {
        staffStores[authUserId] = storeNames[storeId] ?? 'Unassigned store';
      }
    }

    return (usersRes as List<dynamic>).map((row) {
      final map = row as Map<String, dynamic>;
      final authUserId = (map['auth_user_id'] as String?) ?? '';
      return _AdminUser(
        id: (map['id'] as String?) ?? '',
        authUserId: authUserId,
        name: (map['name'] as String?) ?? 'User',
        email: (map['email'] as String?) ?? '',
        role: (map['role'] as String?) ?? 'customer',
        avatarUrl: (map['avatar_url'] as String?) ?? '',
        storeName: staffStores[authUserId] ?? 'Customer',
      );
    }).toList();
  }

  Future<void> _removeStaff(_AdminUser user) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove staff access?'),
            content: Text('Set ${user.name} back to customer role?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoffeePalette.espresso,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    await supabase
        .from('users')
        .update({'role': 'customer'}).eq('auth_user_id', user.authUserId);
    await supabase
        .from('staff_profiles')
        .delete()
        .eq('auth_user_id', user.authUserId);
    await _refresh();
  }

  Future<void> _deleteCustomer(_AdminUser user) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete customer?'),
            content: Text(
              'Delete ${user.name} from users table? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoffeePalette.espresso,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await supabase.from('users').delete().eq('id', user.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Staff', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: FutureBuilder<List<_AdminUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load users.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Text(
                'No users found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemBuilder: (context, index) {
              final user = users[index];
              final isStaff = user.role == 'staff' || user.role == 'admin';
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CoffeePalette.card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: CoffeePalette.caramelSoft,
                      backgroundImage: user.avatarUrl.trim().isEmpty
                          ? null
                          : NetworkImage(user.avatarUrl.trim()),
                      child: user.avatarUrl.trim().isEmpty
                          ? const Icon(Icons.person, color: CoffeePalette.espresso)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_labelRole(user.role)} • ${user.storeName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (isStaff)
                                OutlinedButton.icon(
                                  onPressed: () => _removeStaff(user),
                                  icon: const Icon(Icons.person_remove_outlined),
                                  label: const Text('Remove staff'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: CoffeePalette.espresso,
                                    ),
                                  ),
                                ),
                              if (user.role == 'customer') ...[
                                if (isStaff) const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _deleteCustomer(user),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete customer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CoffeePalette.espresso,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: users.length,
          );
        },
      ),
    );
  }
}

String _labelRole(String role) {
  if (role == 'admin') return 'Admin';
  if (role == 'staff') return 'Staff';
  return 'Customer';
}

class _AdminUser {
  const _AdminUser({
    required this.id,
    required this.authUserId,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.storeName,
  });

  final String id;
  final String authUserId;
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final String storeName;
}
