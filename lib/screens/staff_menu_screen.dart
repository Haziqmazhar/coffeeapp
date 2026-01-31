import 'package:flutter/material.dart';

import '../data/drinks_service.dart';
import '../theme/coffee_palette.dart';

class StaffMenuScreen extends StatefulWidget {
  const StaffMenuScreen({super.key, required this.storeId});

  final String? storeId;

  @override
  State<StaffMenuScreen> createState() => _StaffMenuScreenState();
}

class _StaffMenuScreenState extends State<StaffMenuScreen> {
  final _drinksService = DrinksService();
  late Future<List<Drink>> _drinksFuture;

  @override
  void initState() {
    super.initState();
    _drinksFuture = _drinksService.fetchDrinksForStore(widget.storeId);
  }

  @override
  void didUpdateWidget(covariant StaffMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      _drinksFuture = _drinksService.fetchDrinksForStore(widget.storeId);
    }
  }

  Future<void> _toggleAvailability(Drink drink, bool value) async {
    final storeId = widget.storeId;
    if (storeId == null || storeId.isEmpty) {
      return;
    }
    await _drinksService.setAvailabilityForStore(
      storeId: storeId,
      drinkId: drink.id,
      isAvailable: value,
    );
    setState(() => _drinksFuture = _drinksService.fetchDrinksForStore(storeId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Menu Availability',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: FutureBuilder<List<Drink>>(
        future: _drinksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load menu items.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          if (widget.storeId == null || widget.storeId!.isEmpty) {
            return Center(
              child: Text(
                'No store selected.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final drinks = snapshot.data ?? [];
          if (drinks.isEmpty) {
            return Center(
              child: Text(
                'No drinks found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: drinks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final drink = drinks[index];
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
                          Text(
                            drink.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drink.isAvailable ? 'Available' : 'Unavailable',
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
              );
            },
          );
        },
      ),
    );
  }
}
