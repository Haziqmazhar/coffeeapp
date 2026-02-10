import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/staff_orders_service.dart';
import '../data/stores_service.dart';
import '../theme/coffee_palette.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({
    super.key,
    required this.currentRole,
    required this.onRoleChange,
    required this.canUseAdmin,
    required this.storeId,
  });

  final String currentRole;
  final ValueChanged<String> onRoleChange;
  final bool canUseAdmin;
  final String? storeId;

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  final _ordersService = StaffOrdersService();
  final _storesService = StoresService();
  Store? _store;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  @override
  void didUpdateWidget(covariant StaffHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      _loadStore();
    }
  }

  Future<void> _loadStore() async {
    final storeId = widget.storeId;
    if (storeId == null || storeId.isEmpty) {
      setState(() => _store = null);
      return;
    }
    final store = await _storesService.fetchStoreById(storeId);
    if (!mounted) return;
    setState(() => _store = store);
  }

  Future<void> _toggleStore(bool value) async {
    final store = _store;
    if (store == null) return;
    setState(() {
      _store = Store(id: store.id, name: store.name, isOpen: value);
      _saving = true;
    });
    await _storesService.setStoreOpen(store.id, value);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                currentRole: widget.currentRole,
                onRoleChange: widget.onRoleChange,
                canUseAdmin: widget.canUseAdmin,
              ),
              const SizedBox(height: 18),
              Text(
                'Staff Home',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Live operations overview for today.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _StatusCard(
                title: _store?.name ?? 'No store selected',
                subtitle: 'Store status',
                trailing: Switch(
                  value: _store?.isOpen ?? false,
                  onChanged:
                      _store == null || _saving ? null : (v) => _toggleStore(v),
                  activeColor: CoffeePalette.espresso,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<StaffOrder>>(
                stream:
                    _ordersService.streamOrders(storeId: widget.storeId),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final activeOrders = orders
                      .where((order) => order.status != 'completed')
                      .toList()
                    ..sort(
                      (a, b) => b.createdAt.compareTo(a.createdAt),
                    );
                  final incoming =
                      orders.where((order) => order.status == 'received');
                  final todayCount = orders.where((order) {
                    final created = order.createdAt.toLocal();
                    return created.isAfter(today);
                  }).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Active orders',
                              value: '${activeOrders.length}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: 'Incoming',
                              value: '${incoming.length}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: 'Today',
                              value: '$todayCount',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatusCard(
                        title: 'Live order preview',
                        subtitle: 'Latest active orders',
                        trailing: const Icon(
                          Icons.receipt_long,
                          color: CoffeePalette.espresso,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (activeOrders.isEmpty)
                        Text(
                          'No active orders right now.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...activeOrders.take(3).map(
                              (order) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _OrderPreviewCard(order: order),
                              ),
                            ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentRole,
    required this.onRoleChange,
    required this.canUseAdmin,
  });

  final String currentRole;
  final ValueChanged<String> onRoleChange;
  final bool canUseAdmin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: CoffeePalette.card,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => _RolePicker(
                currentRole: currentRole,
                canUseAdmin: canUseAdmin,
              ),
            );
            if (selected != null && selected != currentRole) {
              onRoleChange(selected);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CoffeePalette.espresso,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentRole == 'staff'
                      ? 'Staff'
                      : currentRole == 'admin'
                          ? 'Admin'
                          : 'Customer',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          'CoffeeArq',
          style: GoogleFonts.baloo2(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: CoffeePalette.espresso,
          ),
        ),
      ],
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.currentRole,
    required this.canUseAdmin,
  });

  final String currentRole;
  final bool canUseAdmin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...[
              'customer',
              'staff',
              if (canUseAdmin) 'admin',
            ].map((role) {
              final isSelected = role == currentRole;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  role == 'staff'
                      ? 'Staff'
                      : role == 'admin'
                          ? 'Admin'
                          : 'Customer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: CoffeePalette.espresso)
                    : const Icon(Icons.circle_outlined,
                        color: CoffeePalette.espressoSoft),
                onTap: () => Navigator.of(context).pop(role),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

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
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: CoffeePalette.espresso),
          ),
        ],
      ),
    );
  }
}

class _OrderPreviewCard extends StatelessWidget {
  const _OrderPreviewCard({required this.order});

  final StaffOrder order;

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(order.createdAt);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Order #${order.id.substring(0, 6).toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CoffeePalette.caramelSoft,
        borderRadius: BorderRadius.circular(12),
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
