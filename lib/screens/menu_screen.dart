import 'package:flutter/material.dart';

import '../data/drinks_service.dart';
import '../theme/coffee_palette.dart';
import 'drink_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.onAddToCart,
    this.initialCategory = 'All',
  });

  final void Function(String name, double price) onAddToCart;
  final String initialCategory;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const List<String> _categories = [
    'All',
    'Hot',
    'Cold',
    'Seasonal',
    'Food',
  ];

  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'All';
  }

  void _selectCategory(String label) {
    setState(() => _selectedCategory = label);
  }

  @override
  Widget build(BuildContext context) {
    final drinksService = DrinksService();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menu', style: Theme.of(context).textTheme.titleLarge),
                const Icon(Icons.search, color: CoffeePalette.espresso),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _categories
                  .map(
                    (label) => _MenuTab(
                      label: label,
                      isSelected: _selectedCategory == label,
                      onTap: () => _selectCategory(label),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Drink>>(
              future: drinksService.fetchDrinks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load menu.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final drinks = snapshot.data ?? [];
                if (drinks.isEmpty) {
                  return Center(
                    child: Text(
                      'No drinks available yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final hasCategory =
                    drinks.any((drink) => (drink.category ?? '').isNotEmpty);
                final filtered = hasCategory && _selectedCategory != 'All'
                    ? drinks
                        .where(
                          (drink) =>
                              (drink.category ?? '').toLowerCase() ==
                              _selectedCategory.toLowerCase(),
                        )
                        .toList()
                    : drinks;
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No items in this category.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final drink = filtered[index];
                    return _MenuRow(
                      item: _MenuItemView(
                        name: drink.name,
                        subtitle: drink.description.isEmpty
                            ? 'Freshly crafted'
                            : drink.description,
                        priceValue: drink.price,
                        icon: Icons.local_cafe,
                        imagePath: _drinkImageMap[drink.name],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DrinkDetailScreen(
                              name: drink.name,
                              subtitle: drink.description.isEmpty
                                  ? 'Freshly crafted'
                                  : drink.description,
                              basePrice: drink.price,
                              onAddToCart: (price) {
                                widget.onAddToCart(drink.name, price);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CoffeePalette.espresso : CoffeePalette.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : CoffeePalette.espresso,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onTap});

  final _MenuItemView item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: CoffeePalette.caramelSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: item.imagePath == null
                  ? Icon(item.icon, color: CoffeePalette.espresso)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        item.imagePath!,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              item.priceLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: CoffeePalette.espresso),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemView {
  const _MenuItemView({
    required this.name,
    required this.subtitle,
    required this.priceValue,
    required this.icon,
    required this.imagePath,
  });

  final String name;
  final String subtitle;
  final double priceValue;
  final IconData icon;
  final String? imagePath;

  String get priceLabel => '\$${priceValue.toStringAsFixed(2)}';
}

const _drinkImageMap = {
  'Classic Latte': 'assets/images/latte.jpg',
  'Strawberry Latte': 'assets/images/strawberrylatte.jpg',
  'Matcha Latte': 'assets/images/matchalatte.jpg',
};
