import 'package:flutter/material.dart';

import '../data/payments_service.dart';
import '../data/profile_service.dart';
import '../theme/coffee_palette.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  Future<List<SavedPaymentMethod>>? _methodsFuture;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final profile = await ProfileService().fetchProfile();
    if (profile == null) {
      setState(() => _methodsFuture = Future.value([]));
      return;
    }
    setState(
      () => _methodsFuture = _paymentsService.fetchPaymentMethods(profile.id),
    );
  }

  Future<void> _openAddCard() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCardScreen()),
    );
    if (added == true) {
      await _loadMethods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title:
            Text('Payment Methods', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: FutureBuilder<List<SavedPaymentMethod>>(
        future: _methodsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            children: [
              if (items.isEmpty)
                Text(
                  'No saved cards yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...items.map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CardTile(
                      brand: method.brand,
                      last4: method.last4,
                      expiry: method.expiryLabel,
                      isDefault: method.isDefault,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _openAddCard,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CoffeePalette.espresso),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.add, color: CoffeePalette.espresso),
                label: const Text('Add payment method'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  final String brand;
  final String last4;
  final String expiry;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: CoffeePalette.caramelSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card, color: CoffeePalette.espresso),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$brand •••• $last4',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Expires $expiry',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CoffeePalette.caramelSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Default',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CoffeePalette.espresso,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
