import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../data/payments_service.dart';
import '../data/profile_service.dart';
import '../theme/coffee_palette.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  bool _isLoading = false;

  Future<void> _saveCard() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService().fetchProfile();
      if (profile == null) {
        throw StateError('Not signed in');
      }

      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(email: profile.email, name: profile.name),
          ),
        ),
      );

      final card = paymentMethod.card;
      if (card == null) {
        throw StateError('Card details not available');
      }

      final added = await _paymentsService.addPaymentMethod(
        userId: profile.id,
        brand: card.brand ?? 'Card',
        last4: card.last4 ?? '----',
        expMonth: card.expMonth ?? 0,
        expYear: card.expYear ?? 0,
        stripePaymentMethodId: paymentMethod.id,
        isDefault: true,
      );

      if (!mounted) return;
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card already added.')),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add card: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Add Card', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoffeePalette.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CardField(
                enablePostalCode: false,
                style: TextStyle(color: CoffeePalette.espresso),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoffeePalette.espresso,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save card'),
            ),
          ],
        ),
      ),
    );
  }
}
