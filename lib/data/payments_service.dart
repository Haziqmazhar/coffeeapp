import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class SavedPaymentMethod {
  SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  factory SavedPaymentMethod.fromMap(Map<String, dynamic> data) {
    return SavedPaymentMethod(
      id: data['id'] as String,
      brand: (data['brand'] as String?) ?? 'Card',
      last4: (data['last4'] as String?) ?? '----',
      expMonth: (data['exp_month'] as int?) ?? 0,
      expYear: (data['exp_year'] as int?) ?? 0,
      isDefault: (data['is_default'] as bool?) ?? false,
    );
  }

  String get expiryLabel => '${expMonth.toString().padLeft(2, '0')}/$expYear';
}

class PaymentsService {
  Future<String> createPaymentIntent({
    required int amount,
    String currency = 'usd',
  }) async {
    final response = await supabase.functions.invoke(
      'create-payment-intent',
      body: {
        'amount': amount,
        'currency': currency,
      },
    );

    final data = response.data;
    if (data is Map && data['client_secret'] != null) {
      return data['client_secret'] as String;
    }

    throw StateError('Payment intent creation failed');
  }

  Future<String> createSetupIntent() async {
    final response = await supabase.functions.invoke(
      'create-setup-intent',
      body: const {},
    );

    final data = response.data;
    if (data is Map && data['client_secret'] != null) {
      return data['client_secret'] as String;
    }

    throw StateError('Setup intent creation failed');
  }

  Future<List<SavedPaymentMethod>> fetchPaymentMethods(String userId) async {
    final response = await supabase
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => SavedPaymentMethod.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<bool> addPaymentMethod({
    required String userId,
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    required String stripePaymentMethodId,
    bool isDefault = false,
  }) async {
    final existing = await supabase
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .eq('last4', last4)
        .eq('exp_month', expMonth)
        .eq('exp_year', expYear)
        .maybeSingle();

    if (existing != null) {
      return false;
    }

    await supabase.from('payment_methods').insert({
      'user_id': userId,
      'brand': brand,
      'last4': last4,
      'exp_month': expMonth,
      'exp_year': expYear,
      'stripe_payment_method_id': stripePaymentMethodId,
      'is_default': isDefault,
    });
    return true;
  }

  Future<void> setDefaultPaymentMethod({
    required String userId,
    required String paymentMethodId,
  }) async {
    await supabase
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', userId);
    await supabase
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', paymentMethodId);
  }
}
