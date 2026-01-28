import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../theme/coffee_palette.dart';
import 'order_status_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.subtotal,
  });

  final List<CartItem> items;
  final double subtotal;

  double get _tax => subtotal * 0.08;
  double get _total => subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Checkout', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          _SectionTitle(label: 'Pickup'),
          const SizedBox(height: 8),
          _InfoCard(
            title: 'Downtown Cafe',
            subtitle: 'Pick-up in 6–9 min',
            actionLabel: 'Change store',
            onAction: () {},
          ),
          const SizedBox(height: 16),
          _SectionTitle(label: 'Order Summary'),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LineItem(
                label: '${item.quantity}× ${item.name}',
                value: '\$${(item.price * item.quantity).toStringAsFixed(2)}',
              ),
            ),
          ),
          const SizedBox(height: 6),
          _LineItem(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
          _LineItem(label: 'Tax (8%)', value: '\$${_tax.toStringAsFixed(2)}'),
          _LineItem(label: 'Total', value: '\$${_total.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          _SectionTitle(label: 'Payment'),
          const SizedBox(height: 8),
          _InfoCard(
            title: 'Visa •••• 4242',
            subtitle: 'Tap to change',
            actionLabel: 'Change',
            onAction: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton(
          onPressed: items.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderStatusScreen(
                        items: items,
                        total: _total,
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: CoffeePalette.espresso,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text('Place Order  \$${_total.toStringAsFixed(2)}'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: CoffeePalette.espresso),
        ),
      ],
    );
  }
}
