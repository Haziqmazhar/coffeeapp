import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class Drink {
  Drink({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.category,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String? category;
  final bool isAvailable;

  factory Drink.fromMap(Map<String, dynamic> data) {
    return Drink(
      id: data['id'] as String,
      name: data['name'] as String,
      description: (data['description'] as String?) ?? '',
      price: (data['price'] as num).toDouble(),
      category: data['category'] as String?,
      isAvailable: (data['is_available'] as bool?) ?? true,
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

  Future<List<Drink>> fetchDrinksForStore(String? storeId) async {
    final drinks = await fetchDrinks();
    if (storeId == null || storeId.isEmpty) {
      return drinks;
    }

    final response = await supabase
        .from('store_drink_availability')
        .select('drink_id, is_available')
        .eq('store_id', storeId);

    final availability = <String, bool>{};
    for (final row in (response as List<dynamic>)) {
      final data = row as Map<String, dynamic>;
      availability[data['drink_id'] as String] =
          (data['is_available'] as bool?) ?? true;
    }

    return drinks
        .map(
          (drink) => Drink(
            id: drink.id,
            name: drink.name,
            description: drink.description,
            price: drink.price,
            category: drink.category,
            isAvailable: availability[drink.id] ?? drink.isAvailable,
          ),
        )
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

  Future<void> setAvailability({
    required String drinkId,
    required bool isAvailable,
  }) async {
    await supabase
        .from('drinks')
        .update({'is_available': isAvailable})
        .eq('id', drinkId);
  }

  Future<void> setAvailabilityForStore({
    required String storeId,
    required String drinkId,
    required bool isAvailable,
  }) async {
    await supabase.from('store_drink_availability').upsert({
      'store_id': storeId,
      'drink_id': drinkId,
      'is_available': isAvailable,
    }, onConflict: 'store_id,drink_id');
  }
}
