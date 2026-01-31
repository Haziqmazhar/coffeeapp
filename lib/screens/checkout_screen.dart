import "package:flutter/material.dart";

import "package:flutter_stripe/flutter_stripe.dart";

import "../data/orders_service.dart";
import "../data/payments_service.dart";
import "../data/profile_service.dart";
import "../models/cart_item.dart";
import "../theme/coffee_palette.dart";
import "payment_methods_screen.dart";
import "order_status_screen.dart";

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.subtotal,
    required this.storeName,
    required this.storeId,
    required this.onOrderPlaced,
    required this.onReorder,
  });

  final List<CartItem> items;
  final double subtotal;
  final String storeName;
  final String? storeId;
  final VoidCallback onOrderPlaced;
  final void Function(List<CartItem> items) onReorder;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<_PaymentSummary?> _paymentFuture;

  @override
  void initState() {
    super.initState();
    _paymentFuture = _fetchPaymentSummary();
  }

  void _refreshPayment() {
    setState(() => _paymentFuture = _fetchPaymentSummary());
  }

  double get _tax => widget.subtotal * 0.08;
  double get _total => widget.subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text("Checkout", style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          const _SectionTitle(label: "Pickup"),
          const SizedBox(height: 8),
          _InfoCard(
            title: widget.storeName,
            subtitle: "Pick-up in 6-9 min",
            actionLabel: "Change store",
            onAction: () {},
          ),
          const SizedBox(height: 16),
          const _SectionTitle(label: "Order Summary"),
          const SizedBox(height: 8),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LineItem(
                label: "${item.quantity}x ${item.name}",
                value: "\$${(item.price * item.quantity).toStringAsFixed(2)}",
              ),
            ),
          ),
          const SizedBox(height: 6),
          _LineItem(label: "Subtotal", value: "\$${widget.subtotal.toStringAsFixed(2)}"),
          _LineItem(label: "Tax (8%)", value: "\$${_tax.toStringAsFixed(2)}"),
          _LineItem(label: "Total", value: "\$${_total.toStringAsFixed(2)}"),
          const SizedBox(height: 16),
          const _SectionTitle(label: "Payment"),
          const SizedBox(height: 8),
          FutureBuilder<_PaymentSummary?>(
            future: _paymentFuture,
            builder: (context, snapshot) {
              final payment = snapshot.data;
              final title = payment == null
                  ? "No payment method"
                  : "${payment.brand} **** ${payment.last4}";
              final subtitle = payment == null
                  ? "Add a card to continue"
                  : "Tap to change";
              return _InfoCard(
                title: title,
                subtitle: subtitle,
                actionLabel: "Change",
                onAction: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsScreen(),
                    ),
                  );
                  if (!mounted) return;
                  _refreshPayment();
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _PlaceOrderButton(
          items: widget.items,
          total: _total,
          storeName: widget.storeName,
          storeId: widget.storeId,
          onOrderPlaced: widget.onOrderPlaced,
          onReorder: widget.onReorder,
        ),
      ),
    );
  }
}

class _PlaceOrderButton extends StatefulWidget {
  const _PlaceOrderButton({
    required this.items,
    required this.total,
    required this.storeName,
    required this.storeId,
    required this.onOrderPlaced,
    required this.onReorder,
  });

  final List<CartItem> items;
  final double total;
  final String storeName;
  final String? storeId;
  final VoidCallback onOrderPlaced;
  final void Function(List<CartItem> items) onReorder;

  @override
  State<_PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends State<_PlaceOrderButton> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.items.isEmpty || _submitting
          ? null
          : () async {
              final profile = await ProfileService().fetchProfile();
              if (profile == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please sign in first.")),
                );
                return;
              }

              final methods =
                  await PaymentsService().fetchPaymentMethods(profile.id);
              if (methods.isEmpty) {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                );
                return;
              }

              setState(() => _submitting = true);
              try {
                final payment = PaymentsService();
                final amount = (widget.total * 100).round();
                final clientSecret =
                    await payment.createPaymentIntent(amount: amount);
                await Stripe.instance.initPaymentSheet(
                  paymentSheetParameters: SetupPaymentSheetParameters(
                    paymentIntentClientSecret: clientSecret,
                    merchantDisplayName: "CoffeeArq",
                  ),
                );
                await Stripe.instance.presentPaymentSheet();

                final service = OrdersService();
                final order = await service.createOrder(
                  items: widget.items,
                  total: widget.total,
                  storeName: widget.storeName,
                  storeId: widget.storeId,
                );
                widget.onOrderPlaced();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Order placed")),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderStatusScreen(
                      order: order,
                      items: widget.items,
                      total: widget.total,
                      onReorder: widget.onReorder,
                    ),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to place order.")),
                );
              } finally {
                if (mounted) setState(() => _submitting = false);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: CoffeePalette.espresso,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: _submitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text("Place Order  \$${widget.total.toStringAsFixed(2)}"),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

Future<_PaymentSummary?> _fetchPaymentSummary() async {
  final profile = await ProfileService().fetchProfile();
  if (profile == null) return null;
  final methods = await PaymentsService().fetchPaymentMethods(profile.id);
  if (methods.isEmpty) return null;
  final defaultMethod =
      methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);
  return _PaymentSummary(
    brand: defaultMethod.brand,
    last4: defaultMethod.last4,
  );
}

class _PaymentSummary {
  const _PaymentSummary({required this.brand, required this.last4});

  final String brand;
  final String last4;
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: CoffeePalette.espresso),
        ),
      ],
    );
  }
}
