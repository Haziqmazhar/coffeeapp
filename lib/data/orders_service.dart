import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import 'supabase_client.dart';

class Order {
  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    this.storeName,
    this.storeId,
  });

  final String id;
  final String status;
  final double total;
  final DateTime createdAt;
  final String? storeName;
  final String? storeId;

  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      id: data['id'] as String,
      status: data['status'] as String,
      total: (data['total'] as num).toDouble(),
      createdAt: DateTime.parse(data['created_at'] as String),
      storeName: data['store_name'] as String?,
      storeId: data['store_id'] as String?,
    );
  }
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      id: data['id'] as String,
      name: data['name'] as String,
      quantity: data['quantity'] as int,
      unitPrice: (data['unit_price'] as num).toDouble(),
    );
  }
}

class OrdersService {
  Session? get _session => supabase.auth.currentSession;

  Future<List<Order>> fetchOrders() async {
    final session = _session;
    if (session == null) return [];

    final user = await supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', session.user.id)
        .maybeSingle();

    if (user == null) return [];
    final userId = user['id'] as String;

    final response = await supabase
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Order.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Order> createOrder({
    required List<CartItem> items,
    required double total,
    String? storeName,
    String? storeId,
  }) async {
    final session = _session;
    if (session == null) {
      throw StateError('Not signed in');
    }

    final user = await supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', session.user.id)
        .single();

    final userId = user['id'] as String;

    final order = await supabase
        .from('orders')
        .insert({
          'user_id': userId,
          'total': total,
          'status': 'received',
          if (storeName != null) 'store_name': storeName,
          if (storeId != null) 'store_id': storeId,
        })
        .select()
        .single();

    final orderId = order['id'] as String;
    final orderItems = items
        .map((item) => {
              'order_id': orderId,
              'name': item.name,
              'quantity': item.quantity,
              'unit_price': item.price,
            })
        .toList();

    if (orderItems.isNotEmpty) {
      await supabase.from('order_items').insert(orderItems);
    }

    return Order.fromMap(order);
  }

  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final response = await supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    return (response as List<dynamic>)
        .map((row) => OrderItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
