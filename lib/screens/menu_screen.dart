import 'package:flutter/material.dart';

import '../theme/coffee_palette.dart';
import 'drink_detail_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.onAddToCart});

  final void Function(String name, double price) onAddToCart;

  @override
  Widget build(BuildContext context) {
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
              children: const [
                _MenuTab(label: 'Hot'),
                _MenuTab(label: 'Cold'),
                _MenuTab(label: 'Seasonal'),
                _MenuTab(label: 'Food'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: _menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      return _MenuRow(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DrinkDetailScreen(
                                name: item.name,
                                subtitle: item.subtitle,
                                basePrice: item.priceValue,
                                onAddToCart: (price) {
                                  onAddToCart(item.name, price);
                                },
                              ),
                            ),
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
  const _MenuTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onTap});

  final MenuItem item;
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
              child: Icon(item.icon, color: CoffeePalette.espresso),
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

class MenuItem {
  const MenuItem({
    required this.name,
    required this.subtitle,
    required this.priceValue,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final double priceValue;
  final IconData icon;

  String get priceLabel => '\$${priceValue.toStringAsFixed(2)}';
}

const _menuItems = [
  MenuItem(
    name: 'Iced Oat Milk Latte',
    subtitle: '2 shots, 50% sweet',
    priceValue: 5.25,
    icon: Icons.coffee_rounded,
  ),
  MenuItem(
    name: 'Cold Brew',
    subtitle: 'Smooth, bold',
    priceValue: 4.50,
    icon: Icons.icecream,
  ),
  MenuItem(
    name: 'Caramel Cappuccino',
    subtitle: 'Foamy with caramel drizzle',
    priceValue: 5.75,
    icon: Icons.local_cafe,
  ),
  MenuItem(
    name: 'Seasonal Spice Latte',
    subtitle: 'Limited batch, cozy blend',
    priceValue: 6.10,
    icon: Icons.local_drink,
  ),
];
