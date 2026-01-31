import 'package:flutter/material.dart';

import '../data/drinks_service.dart';
import '../data/staff_orders_service.dart';
import '../data/stores_service.dart';
import '../theme/coffee_palette.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  static const String _defaultStoreName = 'Downtown Cafe';
  final _storesService = StoresService();
  final _ordersService = StaffOrdersService();
  final _drinksService = DrinksService();

  List<Store> _stores = [];
  Store? _selectedStore;
  bool _loadingStores = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await _storesService.fetchStores();
      if (!mounted) return;
      final preferred = stores.firstWhere(
        (store) => store.name.toLowerCase() == _defaultStoreName.toLowerCase(),
        orElse: () => stores.isNotEmpty ? stores.first : Store(id: '', name: _defaultStoreName, isOpen: true),
      );
      setState(() {
        _stores = stores;
        _selectedStore = stores.isNotEmpty ? preferred : preferred;
        _loadingStores = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStores = false);
    }
  }

  Future<void> _setStoreOpen(bool value) async {
    final store = _selectedStore;
    if (store == null) return;
    await _storesService.setStoreOpen(store.id, value);
    if (!mounted) return;
    setState(() {
      _selectedStore = Store(id: store.id, name: store.name, isOpen: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeId = _selectedStore?.id;
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text(
          'Store Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          _buildStoreHeader(),
          const SizedBox(height: 16),
          Text('Live Orders', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _LiveOrdersSection(
            storeName: storeName,
            ordersService: _ordersService,
          ),
          const SizedBox(height: 20),
          Text('Availability', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _AvailabilitySection(
            drinksService: _drinksService,
            storeId: _selectedStore?.id,
          ),
          const SizedBox(height: 20),
          Text('Earnings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _EarningsSection(
            ordersService: _ordersService,
            storeId: storeId,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    if (_loadingStores) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stores.isEmpty && (_selectedStore?.id.isEmpty ?? true)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CoffeePalette.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No stores found in Supabase. Add a store to enable dashboard controls.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final hasSingleStore = _stores.length <= 1;
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
          Text('Store Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (hasSingleStore)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: CoffeePalette.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _selectedStore?.name ?? _defaultStoreName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          else
            DropdownButtonFormField<Store>(
              value: _selectedStore,
              items: _stores
                  .map(
                    (store) => DropdownMenuItem(
                      value: store,
                      child: Text(store.name),
                    ),
                  )
                  .toList(),
              onChanged: (store) {
                if (store == null) return;
                setState(() => _selectedStore = store);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: CoffeePalette.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedStore?.isOpen == true
                      ? 'Shop is Open'
                      : 'Shop is Closed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Switch(
                value: _selectedStore?.isOpen ?? false,
                onChanged: _setStoreOpen,
                activeColor: CoffeePalette.espresso,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveOrdersSection extends StatelessWidget {
  const _LiveOrdersSection({
    required this.storeName,
    required this.ordersService,
  });

  final String? storeName;
  final StaffOrdersService ordersService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffOrder>>(
      stream: ordersService.streamOrders(storeName: storeName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Failed to load orders.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        final orders = snapshot.data ?? [];
        final activeOrders =
            orders.where((order) => order.status != 'completed').toList();
        if (activeOrders.isEmpty) {
          return Text(
            'No active orders right now.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        final newCount =
            activeOrders.where((order) => order.status == 'received').length;
        return Column(
          children: [
            if (newCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CoffeePalette.caramelSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        color: CoffeePalette.espresso),
                    const SizedBox(width: 8),
                    Text(
                      '$newCount new order${newCount == 1 ? '' : 's'} received',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: CoffeePalette.espresso),
                    ),
                  ],
                ),
              ),
            ...activeOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(
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
                ),
              ),
            ),
          ],
        );
      },
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
      return const _OrderAction(label: 'Complete order', nextStatus: 'completed');
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

class _AvailabilitySection extends StatefulWidget {
  const _AvailabilitySection({
    required this.drinksService,
    required this.storeId,
  });

  final DrinksService drinksService;
  final String? storeId;

  @override
  State<_AvailabilitySection> createState() => _AvailabilitySectionState();
}

class _AvailabilitySectionState extends State<_AvailabilitySection> {
  late Future<List<Drink>> _drinksFuture;

  @override
  void initState() {
    super.initState();
    _drinksFuture = widget.drinksService.fetchDrinksForStore(widget.storeId);
  }

  Future<void> _toggleAvailability(Drink drink, bool value) async {
    final storeId = widget.storeId;
    if (storeId == null || storeId.isEmpty) return;
    await widget.drinksService.setAvailabilityForStore(
      storeId: storeId,
      drinkId: drink.id,
      isAvailable: value,
    );
    setState(() => _drinksFuture = widget.drinksService.fetchDrinksForStore(storeId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Drink>>(
      future: _drinksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Failed to load menu items.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        final drinks = snapshot.data ?? [];
        if (widget.storeId == null || widget.storeId!.isEmpty) {
          return Text(
            'No store selected.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        if (drinks.isEmpty) {
          return Text(
            'No drinks found.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(
          children: drinks
              .map(
                (drink) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CoffeePalette.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drink.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              drink.isAvailable
                                  ? 'Available'
                                  : 'Unavailable',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: drink.isAvailable,
                        onChanged: (value) =>
                            _toggleAvailability(drink, value),
                        activeColor: CoffeePalette.espresso,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EarningsSection extends StatelessWidget {
  const _EarningsSection({
    required this.ordersService,
    required this.storeId,
  });

  final StaffOrdersService ordersService;
  final String? storeId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StaffOrder>>(
      future: ordersService.fetchCompletedOrders(storeId: storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Failed to load earnings.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Text(
            'No completed orders yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        final today = DateTime.now();
        final totalsByDay = <String, double>{};
        for (final order in orders) {
          final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
          final key = _dateKey(date);
          totalsByDay[key] = (totalsByDay[key] ?? 0) + order.total;
        }

        final todayKey = _dateKey(today);
        final todayTotal = totalsByDay[todayKey] ?? 0;

        final recentDays = totalsByDay.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));
        final recentList = recentDays.take(7).toList();

        return Column(
          children: [
            _EarningsCard(
              title: 'Today',
              value: '\$${todayTotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            ...recentList.map(
              (entry) => _EarningsRow(
                dateLabel: _formatDateLabel(entry.key),
                value: '\$${entry.value.toStringAsFixed(2)}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.title, required this.value});

  final String title;
  final String value;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
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

class _EarningsRow extends StatelessWidget {
  const _EarningsRow({required this.dateLabel, required this.value});

  final String dateLabel;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: CoffeePalette.espresso),
          ),
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

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateLabel(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;
  return '${parts[1]}/${parts[2]}';
}
