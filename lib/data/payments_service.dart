import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

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
}
