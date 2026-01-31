import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class Profile {
  Profile({
    required this.id,
    required this.authUserId,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.avatarUrl,
    required this.addresses,
    required this.orderUpdates,
    required this.pickupReminders,
  });

  final String id;
  final String authUserId;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String avatarUrl;
  final List<String> addresses;
  final bool orderUpdates;
  final bool pickupReminders;

  factory Profile.fromMap(Map<String, dynamic> data) {
    return Profile(
      id: data['id'] as String,
      authUserId: data['auth_user_id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      role: (data['role'] as String?) ?? 'customer',
      phone: (data['phone'] as String?) ?? '',
      avatarUrl: (data['avatar_url'] as String?) ?? '',
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      orderUpdates: (data['order_updates'] as bool?) ?? true,
      pickupReminders: (data['pickup_reminders'] as bool?) ?? false,
    );
  }
}

class ProfileService {
  Session? get _session => supabase.auth.currentSession;

  Future<Profile?> fetchProfile() async {
    final session = _session;
    if (session == null) return null;

    final response = await supabase
        .from('users')
        .select()
        .eq('auth_user_id', session.user.id)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromMap(response);
  }

  Future<Profile> upsertProfile({
    required String name,
    required String email,
    String? role,
    String? phone,
    String? avatarUrl,
    List<String>? addresses,
    bool? orderUpdates,
    bool? pickupReminders,
  }) async {
    final session = _session;
    if (session == null) {
      throw StateError('Not signed in');
    }

    final Map<String, dynamic> payload = {
      'auth_user_id': session.user.id,
      'name': name,
      'email': email,
    };
    if (orderUpdates != null) {
      payload['order_updates'] = orderUpdates;
    }
    if (pickupReminders != null) {
      payload['pickup_reminders'] = pickupReminders;
    }
    if (role != null) {
      payload['role'] = role;
    }
    if (phone != null) {
      payload['phone'] = phone;
    }
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }
    if (addresses != null) {
      payload['addresses'] = addresses;
    }

    final response = await supabase
        .from('users')
        .upsert(payload, onConflict: 'auth_user_id')
        .select()
        .single();

    return Profile.fromMap(response);
  }
}
