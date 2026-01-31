import 'package:flutter/material.dart';

import '../data/staff_orders_service.dart';
import '../theme/coffee_palette.dart';

class StaffOrdersScreen extends StatelessWidget {
  const StaffOrdersScreen({super.key, required this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context) {
    final ordersService = StaffOrdersService();
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Live Orders', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: StreamBuilder<List<StaffOrder>>(
        stream: ordersService.streamOrders(storeId: storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load orders.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final orders = snapshot.data ?? [];
          final activeOrders =
              orders.where((order) => order.status != 'completed').toList();
          if (activeOrders.isEmpty) {
            return Center(
              child: Text(
                'No active orders right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: activeOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = activeOrders[index];
              return _OrderCard(
                order: order,
                onUpdate: ordersService.updateStatus,
                onOpenDetails: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: CoffeePalette.cream,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _OrderDetailSheet(
                      order: order,
                      ordersService: ordersService,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onUpdate,
    required this.onOpenDetails,
  });

  final StaffOrder order;
  final Future<void> Function(String id, String status) onUpdate;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final action = _actionForStatus(order.status);
    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(label: _titleCase(order.status)),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: CoffeePalette.espresso),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${order.id.substring(0, 6).toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(order.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onUpdate(order.id, action.nextStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoffeePalette.espresso,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(action.label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderAction {
  const _OrderAction({required this.label, required this.nextStatus});

  final String label;
  final String nextStatus;
}

_OrderAction? _actionForStatus(String status) {
  switch (status) {
    case 'received':
      return const _OrderAction(label: 'Accept order', nextStatus: 'preparing');
    case 'preparing':
      return const _OrderAction(label: 'Mark as Ready', nextStatus: 'ready');
    case 'ready':
      return const _OrderAction(
          label: 'Complete order', nextStatus: 'completed');
    default:
      return null;
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({
    required this.order,
    required this.ordersService,
  });

  final StaffOrder order;
  final StaffOrdersService ordersService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Order #${order.id.substring(0, 6).toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<StaffOrderItem>>(
            future: ordersService.fetchOrderItems(order.id),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return Text(
                  'No items found.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.name}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          _StatusChip(label: _titleCase(order.status)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CoffeePalette.caramelSoft,
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

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _formatTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
