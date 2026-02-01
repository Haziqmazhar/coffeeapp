import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/staff_orders_service.dart';
import '../data/stores_service.dart';
import '../theme/coffee_palette.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.currentRole,
    required this.onRoleChange,
    required this.canUseAdmin,
  });

  final String currentRole;
  final ValueChanged<String> onRoleChange;
  final bool canUseAdmin;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Store? _selectedStore;

  @override
  Widget build(BuildContext context) {
    final storesService = StoresService();
    final ordersService = StaffOrdersService();
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _TopBar(
                currentRole: widget.currentRole,
                onRoleChange: widget.onRoleChange,
                canUseAdmin: widget.canUseAdmin,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Overview of revenue, store status, and top activity.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<_DashboardData>(
                future: _DashboardData.load(
                  storesService: storesService,
                  ordersService: ordersService,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load dashboard.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  final data = snapshot.data ??
                      _DashboardData(
                        stores: const [],
                        completedOrders: const [],
                      );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      _RevenueCard(orders: data.completedOrders),
                      const SizedBox(height: 16),
                      _StoreStatusCard(
                        stores: data.stores,
                        storesService: storesService,
                      ),
                      const SizedBox(height: 16),
                      _TopCustomersCard(
                        orders: data.completedOrders,
                        stores: data.stores,
                        selectedStore: _selectedStore,
                        onStoreChange: (store) {
                          setState(() => _selectedStore = store);
                        },
                      ),
                      const SizedBox(height: 16),
                      _AuditLogCard(),
                    ],
                  );
                },
              ),
            ),
          ],
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
                  currentRole == 'admin'
                      ? 'Admin'
                      : currentRole == 'staff'
                          ? 'Staff'
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
                  role == 'admin'
                      ? 'Admin'
                      : role == 'staff'
                          ? 'Staff'
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

class _DashboardData {
  const _DashboardData({
    required this.stores,
    required this.completedOrders,
  });

  final List<Store> stores;
  final List<StaffOrder> completedOrders;

  static Future<_DashboardData> load({
    required StoresService storesService,
    required StaffOrdersService ordersService,
  }) async {
    final results = await Future.wait([
      storesService.fetchStores(),
      ordersService.fetchCompletedOrders(),
    ]);
    return _DashboardData(
      stores: results[0] as List<Store>,
      completedOrders: results[1] as List<StaffOrder>,
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.orders});

  final List<StaffOrder> orders;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final totalsByDay = <String, double>{};
    for (final order in orders) {
      final date = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      final key = _dateKey(date);
      totalsByDay[key] = (totalsByDay[key] ?? 0) + order.total;
    }
    final todayKey = _dateKey(today);
    final todayTotal = totalsByDay[todayKey] ?? 0;

    final recentDays = totalsByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final recentList = recentDays.take(7).toList();
    final weekTotal =
        totalsByDay.values.fold(0.0, (sum, value) => sum + value);
    final ratio = weekTotal <= 0 ? 0.0 : (todayTotal / weekTotal);

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
          Text('Revenue', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              _DonutChart(
                ratio: ratio,
                primaryColor: CoffeePalette.espresso,
                secondaryColor: CoffeePalette.latte,
                size: 128,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      '\$${todayTotal.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: CoffeePalette.espresso),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '7-day total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${weekTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentList.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDateLabel(entry.key)),
                  Text('\$${entry.value.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreStatusCard extends StatelessWidget {
  const _StoreStatusCard({
    required this.stores,
    required this.storesService,
  });

  final List<Store> stores;
  final StoresService storesService;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CoffeePalette.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No stores found.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Store Status',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => storesService.setAllStoresOpen(false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCC5C5C)),
                  ),
                  child: const Text(
                    'Shut down',
                    style: TextStyle(color: Color(0xFFB34242)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...stores.map(
            (store) => Row(
              children: [
                Expanded(
                  child: Text(store.name),
                ),
                Switch(
                  value: store.isOpen,
                  onChanged: (value) =>
                      storesService.setStoreOpen(store.id, value),
                  activeColor: CoffeePalette.espresso,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  const _TopCustomersCard({
    required this.orders,
    required this.stores,
    required this.selectedStore,
    required this.onStoreChange,
  });

  final List<StaffOrder> orders;
  final List<Store> stores;
  final Store? selectedStore;
  final ValueChanged<Store?> onStoreChange;

  @override
  Widget build(BuildContext context) {
    final filtered = selectedStore == null
        ? orders
        : orders
            .where((order) => order.storeId == selectedStore!.id)
            .toList();
    final counts = <String, int>{};
    for (final order in filtered) {
      final userId = order.userId ?? 'unknown';
      counts[userId] = (counts[userId] ?? 0) + 1;
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.take(3).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Customers',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: () async {
                  final picked = await showModalBottomSheet<Store?>(
                    context: context,
                    backgroundColor: CoffeePalette.card,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _StoreFilterSheet(
                      stores: stores,
                      selectedId: selectedStore?.id,
                      selectedName: selectedStore?.name,
                    ),
                  );
                  onStoreChange(picked);
                },
                icon: const Icon(Icons.filter_list,
                    color: CoffeePalette.espresso),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedStore != null)
            Text(
              selectedStore!.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Text('No data yet.',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            ...top.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('User ${entry.key.substring(0, 4)}'),
                    Text('${entry.value} orders'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreFilterSheet extends StatelessWidget {
  const _StoreFilterSheet({
    required this.stores,
    required this.selectedId,
    required this.selectedName,
  });

  final List<Store> stores;
  final String? selectedId;
  final String? selectedName;

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
              'Filter by store',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All Stores'),
              trailing: selectedId == null
                  ? const Icon(Icons.check_circle,
                      color: CoffeePalette.espresso)
                  : const Icon(Icons.circle_outlined,
                      color: CoffeePalette.espressoSoft),
              onTap: () => Navigator.of(context).pop(null),
            ),
            ...stores.map((store) {
              final isSelected =
                  selectedId == store.id || selectedName == store.name;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(store.name),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: CoffeePalette.espresso)
                    : const Icon(Icons.circle_outlined,
                        color: CoffeePalette.espressoSoft),
                onTap: () => Navigator.of(context).pop(store),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.ratio,
    required this.primaryColor,
    required this.secondaryColor,
    this.size = 64,
  });

  final double ratio;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _DonutChartPainter(
          ratio: ratio,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.ratio,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double ratio;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - stroke / 2;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = secondaryColor
      ..strokeCap = StrokeCap.round;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = primaryColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    final sweep = 2 * 3.141592653589793 * ratio.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      sweep,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _AuditLogCard extends StatelessWidget {
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
          Text('Audit Log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Recent activity will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateLabel(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;
  return '${parts[1]}/${parts[2]}';
}
