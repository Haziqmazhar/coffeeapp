import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_service.dart';
import '../data/supabase_client.dart';
import '../theme/coffee_palette.dart';
import 'auth_screen.dart';
import 'help_center_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_policy_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _profileService = ProfileService();
  Profile? _profile;
  bool _orderUpdates = true;
  bool _pickupReminders = false;
  bool _notificationsAllowed = true;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPrefs();
    _loadNotificationStatus();
    _authSub = supabase.auth.onAuthStateChange.listen((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _orderUpdates = prefs.getBool('pref_order_updates') ?? true;
      _pickupReminders = prefs.getBool('pref_pickup_reminders') ?? false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadNotificationStatus() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() => _notificationsAllowed = status.isGranted);
  }

  Future<bool> _ensureNotificationsAllowed() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    if (result.isGranted) {
      if (mounted) setState(() => _notificationsAllowed = true);
      return true;
    }
    if (result.isPermanentlyDenied && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable notifications'),
          content: const Text(
            'Notifications are disabled in system settings. Turn them on to get order updates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    }
    if (mounted) setState(() => _notificationsAllowed = false);
    return false;
  }

  Future<void> _loadProfile() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      setState(() => _profile = null);
      return;
    }

    final existing = await _profileService.fetchProfile();
    if (existing != null) {
      if (!mounted) return;
      setState(() {
        _profile = existing;
        _orderUpdates = existing.orderUpdates;
        _pickupReminders = existing.pickupReminders;
      });
      return;
    }

    final meta = session.user.userMetadata ?? {};
    final name = (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        'CoffeeArq User';
    final email = session.user.email ?? '';
    final created = await _profileService.upsertProfile(
      name: name,
      email: email,
      orderUpdates: _orderUpdates,
      pickupReminders: _pickupReminders,
    );
    if (!mounted) return;
    setState(() {
      _profile = created;
      _orderUpdates = created.orderUpdates;
      _pickupReminders = created.pickupReminders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: [
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _ProfileCard(
            name: _profile?.name ?? 'Guest',
            email: _profile?.email ?? 'Sign in to save your profile',
            onEdit: _profile == null
                ? null
                : () async {
                    final updated = await showModalBottomSheet<_ProfileData>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: CoffeePalette.cream,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => _EditProfileSheet(
                        initialName: _profile!.name,
                        initialEmail: _profile!.email,
                      ),
                    );
                    if (updated != null) {
                      final saved = await _profileService.upsertProfile(
                        name: updated.name,
                        email: updated.email,
                        orderUpdates: _orderUpdates,
                        pickupReminders: _pickupReminders,
                      );
                      setState(() => _profile = saved);
                    }
                  },
          ),
          const SizedBox(height: 20),
          Text('Account Settings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: _profile == null
                ? 'Sign in to edit profile'
                : 'Update name and email',
            onTap: _profile == null
                ? null
                : () async {
                    final updated = await showModalBottomSheet<_ProfileData>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: CoffeePalette.cream,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => _EditProfileSheet(
                        initialName: _profile!.name,
                        initialEmail: _profile!.email,
                      ),
                    );
                    if (updated != null) {
                      final saved = await _profileService.upsertProfile(
                        name: updated.name,
                        email: updated.email,
                        orderUpdates: _orderUpdates,
                        pickupReminders: _pickupReminders,
                      );
                      if (!mounted) return;
                      setState(() => _profile = saved);
                    }
                  },
          ),
          const SizedBox(height: 16),
          Text('Payment', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.credit_card,
            title: 'Payment Methods',
            subtitle: 'Visa **** 4242',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaymentMethodsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Notifications',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (!_notificationsAllowed)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoffeePalette.latte,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off_outlined,
                      color: CoffeePalette.espresso),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notifications are off in system settings.',
                      style: TextStyle(color: CoffeePalette.espresso),
                    ),
                  ),
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          _SwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Order updates',
            value: _orderUpdates,
            onChanged: (value) async {
              if (value) {
                final allowed = await _ensureNotificationsAllowed();
                if (!allowed) return;
              }
              setState(() => _orderUpdates = value);
              _loadNotificationStatus();
              _setPref('pref_order_updates', value);
              if (_profile != null) {
                await _profileService.upsertProfile(
                  name: _profile!.name,
                  email: _profile!.email,
                  orderUpdates: value,
                  pickupReminders: _pickupReminders,
                );
              }
            },
          ),
          _SwitchTile(
            icon: Icons.alarm_outlined,
            title: 'Pickup reminders',
            value: _pickupReminders,
            onChanged: (value) async {
              if (value) {
                final allowed = await _ensureNotificationsAllowed();
                if (!allowed) return;
              }
              setState(() => _pickupReminders = value);
              _loadNotificationStatus();
              _setPref('pref_pickup_reminders', value);
              if (_profile != null) {
                await _profileService.upsertProfile(
                  name: _profile!.name,
                  email: _profile!.email,
                  orderUpdates: _orderUpdates,
                  pickupReminders: value,
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Support', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'FAQs and support',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read how we handle data',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const SizedBox(height: 18),
          if (session == null)
            ElevatedButton(
              onPressed: () async {
                final signedIn = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                if (signedIn == true) {
                  await _loadProfile();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CoffeePalette.espresso,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Sign in'),
            )
          else
            OutlinedButton(
              onPressed: () async {
                await supabase.auth.signOut();
                await _loadProfile();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CoffeePalette.espresso),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Sign Out'),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: CoffeePalette.caramelSoft,
            child: Icon(Icons.person, color: CoffeePalette.espresso, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            color: CoffeePalette.espresso,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Icon(icon, color: CoffeePalette.espresso),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CoffeePalette.espressoSoft),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Icon(icon, color: CoffeePalette.espresso),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: CoffeePalette.espresso,
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.initialName,
    required this.initialEmail,
  });

  final String initialName;
  final String initialEmail;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CoffeePalette.espresso),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _ProfileData(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoffeePalette.espresso,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({required this.name, required this.email});

  final String name;
  final String email;
}
