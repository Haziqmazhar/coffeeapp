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
  List<Drink> _drinks = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  @override
  void didUpdateWidget(covariant StaffMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      _loadDrinks();
    }
  }

  Future<void> _loadDrinks() async {
    final storeId = widget.storeId;
    if (storeId == null || storeId.isEmpty) {
      setState(() {
        _drinks = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final drinks = await _drinksService.fetchDrinksForStore(storeId);
    if (!mounted) return;
    setState(() {
      _drinks = drinks;
      _loading = false;
    });
  }

  Future<void> _toggleAvailability(Drink drink, bool value) async {
    final storeId = widget.storeId;
    if (storeId == null || storeId.isEmpty) {
      return;
    }
    final index = _drinks.indexWhere((item) => item.id == drink.id);
    if (index == -1) return;
    setState(() {
      _drinks[index] = Drink(
        id: drink.id,
        name: drink.name,
        description: drink.description,
        price: drink.price,
        category: drink.category,
        isAvailable: value,
      );
      _saving = true;
    });
    await _drinksService.setAvailabilityForStore(
      storeId: storeId,
      drinkId: drink.id,
      isAvailable: value,
    );
    if (!mounted) return;
    setState(() => _saving = false);
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.storeId == null || widget.storeId!.isEmpty) {
      return Center(
        child: Text(
          'No store selected.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    if (_drinks.isEmpty) {
      return Center(
        child: Text(
          'No drinks found.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: _drinks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final drink = _drinks[index];
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
                onChanged: _saving
                    ? null
                    : (value) => _toggleAvailability(drink, value),
                activeColor: CoffeePalette.espresso,
              ),
            ],
          ),
        );
      },
    );
  }
}
