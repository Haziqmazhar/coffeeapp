import 'package:flutter/material.dart';

import '../data/orders_service.dart' as orders;
import '../models/cart_item.dart';
import '../theme/coffee_palette.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({
    super.key,
    required this.order,
    required this.items,
    required this.total,
    required this.onReorder,
  });

  final orders.Order order;
  final List<CartItem> items;
  final double total;
  final void Function(List<CartItem> items) onReorder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Order Status', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          _StatusCard(
            status: _titleCase(order.status),
            eta: 'Pickup in 6–9 min',
          ),
          const SizedBox(height: 10),
          Text(
            'Order #${order.id.substring(0, 6).toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _ProgressRow(status: order.status),
          const SizedBox(height: 16),
          Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OrderItemRow(
                name: item.name,
                quantity: item.quantity,
                total: item.price * item.quantity,
                imagePath: _drinkImageMap[item.name],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Total  \$${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton(
          onPressed: () {
            onReorder(items);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CoffeePalette.espresso,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text('Order Again'),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final steps = ['received', 'preparing', 'ready'];
    final activeIndex = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= (activeIndex < 0 ? 0 : activeIndex);
        return Expanded(
          child: Row(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color:
                      isActive ? CoffeePalette.espresso : CoffeePalette.latte,
                  shape: BoxShape.circle,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive
                        ? CoffeePalette.espresso
                        : CoffeePalette.latte,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.name,
    required this.quantity,
    required this.total,
    required this.imagePath,
  });

  final String name;
  final int quantity;
  final double total;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: CoffeePalette.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: imagePath == null
              ? const Icon(Icons.local_cafe, color: CoffeePalette.espresso)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$quantity× $name',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '\$${total.toStringAsFixed(2)}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: CoffeePalette.espresso),
        ),
      ],
    );
  }
}

const _drinkImageMap = {
  'Classic Latte': 'assets/images/latte.jpg',
  'Strawberry Latte': 'assets/images/strawberrylatte.jpg',
  'Matcha Latte': 'assets/images/matchalatte.jpg',
};

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.eta});

  final String status;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(status, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(eta, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
