class CartItem {
  CartItem({
    required this.name,
    required this.price,
    required this.details,
    this.imagePath,
    this.quantity = 1,
  });

  final String name;
  final double price;
  final String details;
  final String? imagePath;
  int quantity;

  String get key => '$name|$details';
}
