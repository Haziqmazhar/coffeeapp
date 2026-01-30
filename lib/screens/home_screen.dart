import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/drinks_service.dart';
import '../data/profile_service.dart';
import '../data/supabase_client.dart';
import '../models/cart_item.dart';
import 'drink_detail_screen.dart';
import '../theme/coffee_palette.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.currentStore,
    required this.cartCount,
    required this.cartTotal,
    required this.onQuickAdd,
    required this.onCartTap,
    required this.onStoreTap,
    required this.onCategoryTap,
  });

  final String currentStore;
  final int cartCount;
  final double cartTotal;
  final void Function(CartItem item) onQuickAdd;
  final VoidCallback onCartTap;
  final VoidCallback onStoreTap;
  final void Function(String category) onCategoryTap;

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
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TopBar(),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _StorePill(
                      label: 'Current Store: $currentStore',
                      onTap: onStoreTap,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _GreetingText(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'The Usual',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: FutureBuilder<List<Drink>>(
                    future: DrinksService().fetchDrinks(),
                    builder: (context, snapshot) {
                      final drinks = snapshot.data;
                      final items = drinks == null || drinks.isEmpty
                          ? _homeFavorites
                          : drinks
                              .take(3)
                              .map(
                                (drink) => FavoriteDrink(
                                  name: drink.name,
                                  subtitle: drink.description.isEmpty
                                      ? 'Freshly crafted'
                                      : drink.description,
                                  price: drink.price,
                                  imagePath:
                                      _drinkImageMap[drink.name] ??
                                          _homeFavorites.first.imagePath,
                                  isAvailable: drink.isAvailable,
                                ),
                              )
                              .toList();
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _FavoriteCard(
                            item: item,
                            onQuickAdd: item.isAvailable
                                ? () => onQuickAdd(
                                      CartItem(
                                        name: item.name,
                                        price: item.price,
                                        details: 'M • Oat • 50% • No add-ons',
                                        imagePath: item.imagePath,
                                      ),
                                    )
                                : null,
                            onTap: item.isAvailable
                                ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DrinkDetailScreen(
                                    name: item.name,
                                    subtitle: item.subtitle,
                                    basePrice: item.price,
                                    imagePath: item.imagePath,
                                    onAddToCart: (cartItem) {
                                      onQuickAdd(cartItem);
                                    },
                                  ),
                                ),
                              );
                            }
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Seapress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CategoryChip(
                        icon: Icons.local_cafe_outlined,
                        label: 'Hot Coffee',
                        onTap: () => onCategoryTap('Hot'),
                      ),
                      _CategoryChip(
                        icon: Icons.icecream_outlined,
                        label: 'Cold Drinks',
                        onTap: () => onCategoryTap('Cold'),
                      ),
                      _CategoryChip(
                        icon: Icons.spa_outlined,
                        label: 'Seasonal',
                        onTap: () => onCategoryTap('Seasonal'),
                      ),
                      _CategoryChip(
                        icon: Icons.bakery_dining_outlined,
                        label: 'Food',
                        onTap: () => onCategoryTap('Food'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _PromoCarousel(),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: _CartBar(
            cartCount: cartCount,
            cartTotal: cartTotal,
            onTap: onCartTap,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'CoffeeArq',
        style: GoogleFonts.baloo2(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: CoffeePalette.espresso,
        ),
      ),
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

class _GreetingText extends StatelessWidget {
  const _GreetingText();

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();
    final session = supabase.auth.currentSession;

    if (session == null) {
      return Text(
        'Good Morning.',
        style: Theme.of(context).textTheme.headlineLarge,
      );
    }

    return FutureBuilder<Profile?>(
      future: profileService.fetchProfile(),
      builder: (context, snapshot) {
        final name = snapshot.data?.name;
        final greeting = name == null || name.isEmpty
            ? 'Good Morning.'
            : 'Good Morning, $name.';
        return Text(
          greeting,
          style: Theme.of(context).textTheme.headlineLarge,
        );
      },
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
  const _FavoriteCard({
    required this.item,
    required this.onQuickAdd,
    required this.onTap,
  });

  final FavoriteDrink item;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CoffeePalette.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 110,
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
            if (item.isAvailable)
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              const _UnavailablePill(),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: onQuickAdd,
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
      ),
    );
  }
}

class _UnavailablePill extends StatelessWidget {
  const _UnavailablePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: CoffeePalette.latte,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Unavailable',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: CoffeePalette.espressoSoft),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 112,
        width: 80,
        child: Column(
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
              height: 36,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.cartCount,
    required this.cartTotal,
    required this.onTap,
  });

  final int cartCount;
  final double cartTotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
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
                  '$cartCount Items • \$${cartTotal.toStringAsFixed(2)}',
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
              child:
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController(viewportFraction: 1);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Promotions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _controller,
            itemCount: _promoItems.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final item = _promoItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _PromoCard(
                  title: item.title,
                  subtitle: item.subtitle,
                  badge: item.badge,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promoItems.length,
              (dotIndex) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: dotIndex == _index ? 18 : 6,
                decoration: BoxDecoration(
                  color: dotIndex == _index
                      ? CoffeePalette.espresso
                      : CoffeePalette.espressoSoft.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CoffeePalette.espresso.withOpacity(0.92),
            CoffeePalette.caramel,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoItem {
  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;
}

const _promoItems = [
  _PromoItem(
    title: 'Morning Combo',
    subtitle: 'Any latte + pastry for \$6.90',
    badge: 'Limited',
  ),
  _PromoItem(
    title: 'Iced Week',
    subtitle: '2nd iced drink 50% off',
    badge: 'This Week',
  ),
  _PromoItem(
    title: 'Matcha Fans',
    subtitle: 'Free extra shot today',
    badge: 'Today',
  ),
];

class FavoriteDrink {
  const FavoriteDrink({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.imagePath,
    required this.isAvailable,
  });

  final String name;
  final String subtitle;
  final double price;
  final String imagePath;
  final bool isAvailable;
}

const _homeFavorites = [
  FavoriteDrink(
    name: 'Classic Latte',
    subtitle: 'Smooth, creamy',
    price: 5.25,
    imagePath: 'assets/images/latte.jpg',
    isAvailable: true,
  ),
  FavoriteDrink(
    name: 'Strawberry Latte',
    subtitle: 'Berry cream blend',
    price: 4.50,
    imagePath: 'assets/images/strawberrylatte.jpg',
    isAvailable: true,
  ),
  FavoriteDrink(
    name: 'Matcha Latte',
    subtitle: 'Green tea delight',
    price: 3.75,
    imagePath: 'assets/images/matchalatte.jpg',
    isAvailable: true,
  ),
];

const _drinkImageMap = {
  'Classic Latte': 'assets/images/latte.jpg',
  'Strawberry Latte': 'assets/images/strawberrylatte.jpg',
  'Matcha Latte': 'assets/images/matchalatte.jpg',
};
