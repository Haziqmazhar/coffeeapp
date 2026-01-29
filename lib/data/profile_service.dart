import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class Profile {
  Profile({
    required this.id,
    required this.authUserId,
    required this.name,
    required this.email,
    required this.orderUpdates,
    required this.pickupReminders,
  });

  final String id;
  final String authUserId;
  final String name;
  final String email;
  final bool orderUpdates;
  final bool pickupReminders;

  factory Profile.fromMap(Map<String, dynamic> data) {
    return Profile(
      id: data['id'] as String,
      authUserId: data['auth_user_id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
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

    final response =
        await supabase.from('users').upsert(payload).select().single();

    return Profile.fromMap(response);
  }
}
