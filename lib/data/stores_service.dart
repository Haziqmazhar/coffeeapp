import 'supabase_client.dart';

class Store {
  Store({
    required this.id,
    required this.name,
    required this.isOpen,
  });

  final String id;
  final String name;
  final bool isOpen;

  factory Store.fromMap(Map<String, dynamic> data) {
    return Store(
      id: data['id'] as String,
      name: data['name'] as String,
      isOpen: (data['is_open'] as bool?) ?? true,
    );
  }
}

class StoresService {
  Future<List<Store>> fetchStores() async {
    final response = await supabase.from('stores').select().order('name');
    return (response as List<dynamic>)
        .map((row) => Store.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Store?> fetchStoreById(String storeId) async {
    final response =
        await supabase.from('stores').select().eq('id', storeId).maybeSingle();
    if (response == null) return null;
    return Store.fromMap(response as Map<String, dynamic>);
  }

  Future<void> setStoreOpen(String storeId, bool isOpen) async {
    await supabase.from('stores').update({'is_open': isOpen}).eq('id', storeId);
  }

  Future<void> setAllStoresOpen(bool isOpen) async {
    await supabase.from('stores').update({'is_open': isOpen});
  }
}
