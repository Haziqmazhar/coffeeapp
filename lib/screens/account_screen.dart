import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  List<String> _addresses = const [];
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
        _addresses = existing.addresses;
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
      role: 'customer',
      orderUpdates: _orderUpdates,
      pickupReminders: _pickupReminders,
    );
    if (!mounted) return;
    setState(() {
      _profile = created;
      _addresses = created.addresses;
      _orderUpdates = created.orderUpdates;
      _pickupReminders = created.pickupReminders;
    });
  }

  Future<void> _saveProfileUpdates({
    required String name,
    required String email,
    required String phone,
    required String avatarUrl,
  }) async {
    if (_profile != null) {
      setState(() {
        _profile = Profile(
          id: _profile!.id,
          authUserId: _profile!.authUserId,
          name: name,
          email: email,
          role: _profile!.role,
          phone: phone,
          avatarUrl: avatarUrl,
          addresses: _addresses,
          orderUpdates: _orderUpdates,
          pickupReminders: _pickupReminders,
        );
      });
    }
    final saved = await _profileService.upsertProfile(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      addresses: _addresses,
      orderUpdates: _orderUpdates,
      pickupReminders: _pickupReminders,
    );
    if (!mounted) return;
    setState(() => _profile = saved);
    await _loadProfile();
  }

  Future<void> _saveAddresses(List<String> addresses) async {
    if (_profile == null) return;
    final saved = await _profileService.upsertProfile(
      name: _profile!.name,
      email: _profile!.email,
      phone: _profile!.phone,
      avatarUrl: _profile!.avatarUrl,
      addresses: addresses,
      orderUpdates: _orderUpdates,
      pickupReminders: _pickupReminders,
    );
    if (!mounted) return;
    setState(() {
      _profile = saved;
      _addresses = saved.addresses;
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
            phone: _profile?.phone ?? '',
            avatarUrl: _profile?.avatarUrl ?? '',
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
                        initialPhone: _profile!.phone,
                        initialAvatarUrl: _profile!.avatarUrl,
                        onAvatarSaved: (url) async {
                          await _saveProfileUpdates(
                            name: _profile!.name,
                            email: _profile!.email,
                            phone: _profile!.phone,
                            avatarUrl: url,
                          );
                        },
                      ),
                    );
                    if (updated != null) {
                      await _saveProfileUpdates(
                        name: updated.name,
                        email: updated.email,
                        phone: updated.phone,
                        avatarUrl: updated.avatarUrl,
                      );
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
                : 'Update name, phone, photo',
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
                        initialPhone: _profile!.phone,
                        initialAvatarUrl: _profile!.avatarUrl,
                        onAvatarSaved: (url) async {
                          await _saveProfileUpdates(
                            name: _profile!.name,
                            email: _profile!.email,
                            phone: _profile!.phone,
                            avatarUrl: url,
                          );
                        },
                      ),
                    );
                    if (updated != null) {
                      await _saveProfileUpdates(
                        name: updated.name,
                        email: updated.email,
                        phone: updated.phone,
                        avatarUrl: updated.avatarUrl,
                      );
                    }
                  },
          ),
          _SettingTile(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            subtitle: _addresses.isEmpty
                ? 'Add your pickup locations'
                : '${_addresses.length} saved',
            onTap: _profile == null
                ? null
                : () async {
                    final updated = await showModalBottomSheet<List<String>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: CoffeePalette.cream,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => _EditAddressesSheet(
                        initialAddresses: _addresses,
                      ),
                    );
                    if (updated != null) {
                      await _saveAddresses(updated);
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
                  phone: _profile!.phone,
                  avatarUrl: _profile!.avatarUrl,
                  addresses: _addresses,
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
                  phone: _profile!.phone,
                  avatarUrl: _profile!.avatarUrl,
                  addresses: _addresses,
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
            Column(
              children: [
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
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final signedIn = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(requiredRole: 'staff'),
                      ),
                    );
                    if (signedIn == true) {
                      await _loadProfile();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CoffeePalette.espresso),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Staff login'),
                ),
              ],
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
    required this.phone,
    required this.avatarUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
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
          CircleAvatar(
            radius: 28,
            backgroundColor: CoffeePalette.caramelSoft,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person,
                    color: CoffeePalette.espresso, size: 28)
                : null,
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
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
    required this.initialPhone,
    required this.initialAvatarUrl,
    required this.onAvatarSaved,
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialAvatarUrl;
  final ValueChanged<String> onAvatarSaved;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;
  final _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _avatarController = TextEditingController(text: widget.initialAvatarUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
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
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: CoffeePalette.caramelSoft,
              backgroundImage: _avatarController.text.trim().isNotEmpty
                  ? NetworkImage(_avatarController.text.trim())
                  : null,
              child: _avatarController.text.trim().isEmpty
                  ? const Icon(Icons.person,
                      color: CoffeePalette.espresso, size: 30)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUploadAvatar,
              icon: _uploading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: const Text('Upload from gallery'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CoffeePalette.espresso),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
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
                        phone: _phoneController.text.trim(),
                        avatarUrl: _avatarController.text.trim(),
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

  Future<void> _pickAndUploadAvatar() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 900,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final userId = session.user.id;
      final path = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final publicUrl =
          supabase.storage.from('avatars').getPublicUrl(path);
      _avatarController.text = publicUrl;
      if (mounted) setState(() {});
      widget.onAvatarSaved(publicUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
}

class _EditAddressesSheet extends StatefulWidget {
  const _EditAddressesSheet({required this.initialAddresses});

  final List<String> initialAddresses;

  @override
  State<_EditAddressesSheet> createState() => _EditAddressesSheetState();
}

class _EditAddressesSheetState extends State<_EditAddressesSheet> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialAddresses
        .map((address) => TextEditingController(text: address))
        .toList();
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addAddress() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeAddress(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      if (_controllers.isEmpty) {
        _controllers.add(TextEditingController());
      }
    });
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
          Text('Saved Addresses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ..._controllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Address ${index + 1}',
                        filled: true,
                        fillColor: CoffeePalette.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _removeAddress(index),
                    icon: const Icon(Icons.close),
                    color: CoffeePalette.espressoSoft,
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add, color: CoffeePalette.espresso),
            label: const Text('Add another address'),
          ),
          const SizedBox(height: 12),
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
                    final addresses = _controllers
                        .map((controller) => controller.text.trim())
                        .where((value) => value.isNotEmpty)
                        .toList();
                    Navigator.pop(context, addresses);
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
