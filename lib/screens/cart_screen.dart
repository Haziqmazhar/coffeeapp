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
  });

  final List<CartItem> items;
  final double total;
  final void Function(String name, int delta) onUpdateQuantity;
  final void Function(String name) onRemoveItem;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _handleUpdateQuantity(String name, int delta) {
    widget.onUpdateQuantity(name, delta);
    setState(() {});
  }

  void _handleRemoveItem(String name) {
    widget.onRemoveItem(name);
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
                      const Icon(Icons.local_cafe, color: CoffeePalette.espresso),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: CoffeePalette.espresso,
                            onPressed: () =>
                                _handleUpdateQuantity(item.name, -1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: CoffeePalette.espresso,
                            onPressed: () =>
                                _handleUpdateQuantity(item.name, 1),
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
                            onPressed: () => _handleRemoveItem(item.name),
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
                        subtotal: widget.total,
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
          child: Text('Checkout  \$${widget.total.toStringAsFixed(2)}'),
        ),
      ),
    );
  }
}
