import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/coffee_palette.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CoffeePalette.cream, CoffeePalette.latte],
            ),
          ),
        ),
        Positioned(
          right: -40,
          bottom: 120,
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CoffeePalette.caramelSoft.withOpacity(0.35),
            ),
          ),
        ),
        Positioned(
          left: -60,
          top: 160,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CoffeePalette.latte.withOpacity(0.6),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopDate(),
                const SizedBox(height: 6),
                _TopBar(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _StorePill(
                    label: 'Current Store: Downtown Cafe',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Good Morning, Alex.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 20),
                Text('The Usual', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _homeFavorites.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = _homeFavorites[index];
                      return _FavoriteCard(item: item);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text('Seapress', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _CategoryChip(
                      icon: Icons.local_cafe_outlined,
                      label: 'Hot Coffee',
                    ),
                    _CategoryChip(
                      icon: Icons.icecream_outlined,
                      label: 'Cold Drinks',
                    ),
                    _CategoryChip(
                      icon: Icons.spa_outlined,
                      label: 'Seasonal',
                    ),
                    _CategoryChip(
                      icon: Icons.bakery_dining_outlined,
                      label: 'Food',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: _CartBar(),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: CoffeePalette.caramelSoft,
          child: Icon(Icons.person, color: CoffeePalette.espresso),
        ),
        const SizedBox(width: 10),
        Text(
          'CoffeeArq',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _TopDate extends StatelessWidget {
  const _TopDate();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        'Wednesday, January 28, 2026 at 9:11 AM',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _StorePill extends StatelessWidget {
  const _StorePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CoffeePalette.espresso,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item});

  final FavoriteDrink item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 110,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [CoffeePalette.caramelSoft, CoffeePalette.latte],
                    ),
                  ),
                  child: Icon(item.icon,
                      color: CoffeePalette.espresso, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_cafe, size: 18),
              label: const Text('Quick Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CoffeePalette.espresso,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: const BoxDecoration(
            color: CoffeePalette.espresso,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 76,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: CoffeePalette.espresso,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                '2 Items • \$9.75',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            height: 34,
            width: 34,
            decoration: const BoxDecoration(
              color: CoffeePalette.caramel,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class FavoriteDrink {
  const FavoriteDrink({
    required this.name,
    required this.subtitle,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final IconData icon;
}

const _homeFavorites = [
  FavoriteDrink(
    name: 'Iced Oat Milk Latte',
    subtitle: '2 shots, 50% sweet',
    icon: Icons.coffee_rounded,
  ),
  FavoriteDrink(
    name: 'Cold Brew',
    subtitle: 'Smooth, bold',
    icon: Icons.icecream,
  ),
  FavoriteDrink(
    name: 'Almond Croissant',
    subtitle: 'Warm & flaky',
    icon: Icons.bakery_dining,
  ),
];
