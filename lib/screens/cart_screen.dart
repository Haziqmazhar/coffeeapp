import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../theme/coffee_palette.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.items,
    required this.total,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onCheckoutComplete,
    required this.onReorder,
    required this.storeName,
    required this.storeId,
  });

  final List<CartItem> items;
  final double total;
  final void Function(String key, int delta) onUpdateQuantity;
  final void Function(String key) onRemoveItem;
  final VoidCallback onCheckoutComplete;
  final void Function(List<CartItem> items) onReorder;
  final String storeName;
  final String? storeId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get _total => widget.items.fold(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  void _handleUpdateQuantity(String key, int delta) {
    widget.onUpdateQuantity(key, delta);
    setState(() {});
  }

  void _handleRemoveItem(String key) {
    widget.onRemoveItem(key);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Your Cart', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: widget.items.isEmpty
          ? Center(
              child: Text(
                'Your cart is empty.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final imagePath = item.imagePath ?? _resolveImagePath(item.name);
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
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: CoffeePalette.caramelSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imagePath == null
                            ? const Icon(Icons.local_cafe,
                                color: CoffeePalette.espresso)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: 52,
                                  height: 52,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: CoffeePalette.espresso,
                            onPressed: () =>
                                _handleUpdateQuantity(item.key, -1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: CoffeePalette.espresso,
                            onPressed: () =>
                                _handleUpdateQuantity(item.key, 1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: CoffeePalette.espresso),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: CoffeePalette.espressoSoft,
                            onPressed: () => _handleRemoveItem(item.key),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton(
          onPressed: widget.items.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        items: widget.items,
                        subtotal: _total,
                        storeName: widget.storeName,
                        storeId: widget.storeId,
                        onOrderPlaced: widget.onCheckoutComplete,
                        onReorder: widget.onReorder,
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: CoffeePalette.espresso,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text('Checkout  \$${_total.toStringAsFixed(2)}'),
        ),
      ),
    );
  }
}

String? _resolveImagePath(String name) {
  final normalized = name.toLowerCase();
  for (final entry in _cartImageMap.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

const _cartImageMap = {
  'classic latte': 'assets/images/latte.jpg',
  'strawberry latte': 'assets/images/strawberrylatte.jpg',
  'matcha latte': 'assets/images/matchalatte.jpg',
};
