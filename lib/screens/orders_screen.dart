import 'package:flutter/material.dart';

import '../data/orders_service.dart';
import '../theme/coffee_palette.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersService = OrdersService();
    return SafeArea(
      child: FutureBuilder<List<Order>>(
        future: ordersService.fetchOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final activeOrders =
              orders.where((order) => order.status != 'completed').toList();
          final recentOrders =
              orders.where((order) => order.status == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text('Orders', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Track your active and recent orders',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ] else ...[
                const SizedBox(height: 20),
                Text('Active', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (activeOrders.isEmpty)
                  Text(
                    'No active orders yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...activeOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderCard(
                        status: _titleCase(order.status),
                        eta: _formatDate(order.createdAt),
                        store: 'Downtown Cafe',
                        total: '\$${order.total.toStringAsFixed(2)}',
                        items: 'View details',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text('Recent', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (recentOrders.isEmpty)
                  Text(
                    'No recent orders yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...recentOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderCard(
                        status: _titleCase(order.status),
                        eta: _formatDate(order.createdAt),
                        store: 'Downtown Cafe',
                        total: '\$${order.total.toStringAsFixed(2)}',
                        items: 'View details',
                        compact: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final month = _monthName(local.month);
  return '$month ${local.day}, ${local.year}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.status,
    required this.eta,
    required this.store,
    required this.total,
    required this.items,
    required this.onTap,
    this.compact = false,
  });

  final String status;
  final String eta;
  final String store;
  final String total;
  final String items;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(compact ? 14 : 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(label: status, isActive: status != 'Completed'),
                Text(
                  total,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: CoffeePalette.espresso),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(store, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(items, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(eta, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? CoffeePalette.caramelSoft : CoffeePalette.latte,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoffeePalette.espresso,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
