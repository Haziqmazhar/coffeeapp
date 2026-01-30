import 'package:flutter/material.dart';

import '../data/orders_service.dart';
import '../models/cart_item.dart';
import '../theme/coffee_palette.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    this.onReorder,
  });

  final Order order;
  final void Function(List<CartItem> items)? onReorder;

  @override
  Widget build(BuildContext context) {
    final service = OrdersService();
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Order Details', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: FutureBuilder<List<OrderItem>>(
        future: service.fetchOrderItems(order.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            children: [
              _StatusCard(
                status: _titleCase(order.status),
                eta: 'Pickup in 6-9 min',
              ),
              const SizedBox(height: 10),
              Text(
                'Order #${order.id.substring(0, 6).toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (items.isEmpty)
                Text(
                  'No items found.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OrderItemRow(
                      name: item.name,
                      quantity: item.quantity,
                      total: item.unitPrice * item.quantity,
                      imagePath: _resolveImagePath(item.name),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _LineItem(
                label: 'Total',
                value: '\$${order.total.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              if (onReorder != null && items.isNotEmpty) ...[
                ElevatedButton(
                  onPressed: () {
                    final cartItems = items
                        .map(
                          (item) => CartItem(
                            name: item.name,
                            price: item.unitPrice,
                            quantity: item.quantity,
                            details: 'Reorder',
                            imagePath: _resolveImagePath(item.name),
                          ),
                        )
                        .toList();
                    onReorder!(cartItems);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Items added to cart.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoffeePalette.espresso,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Reorder items'),
                ),
                const SizedBox(height: 16),
              ],
              Text('Store', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _InfoCard(
                title: 'Downtown Cafe',
                subtitle: 'Ready for pickup soon',
              ),
            ],
          );
        },
      ),
    );
  }
}

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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
          height: 48,
          width: 48,
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
                    width: 48,
                    height: 48,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${quantity}x $name',
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

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String? _resolveImagePath(String name) {
  final normalized = name.toLowerCase();
  for (final entry in _drinkImageMap.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

const _drinkImageMap = {
  'classic latte': 'assets/images/latte.jpg',
  'strawberry latte': 'assets/images/strawberrylatte.jpg',
  'matcha latte': 'assets/images/matchalatte.jpg',
};
