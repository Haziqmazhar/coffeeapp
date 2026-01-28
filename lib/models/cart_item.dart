class CartItem {
  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String name;
  final double price;
  int quantity;
}
