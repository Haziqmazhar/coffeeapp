import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class Drink {
  Drink({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final double price;

  factory Drink.fromMap(Map<String, dynamic> data) {
    return Drink(
      id: data['id'] as String,
      name: data['name'] as String,
      description: (data['description'] as String?) ?? '',
      price: (data['price'] as num).toDouble(),
    );
  }
}

class DrinksService {
  Future<List<Drink>> fetchDrinks() async {
    final response = await supabase.from('drinks').select().order('name');
    return (response as List<dynamic>)
        .map((row) => Drink.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createDrink({
    required String name,
    required String description,
    required double price,
  }) async {
    await supabase.from('drinks').insert({
      'name': name,
      'description': description,
      'price': price,
    });
  }
}
