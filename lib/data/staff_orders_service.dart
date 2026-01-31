import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class StaffOrder {
  StaffOrder({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    this.storeId,
    this.storeName,
    this.userId,
  });

  final String id;
  final String status;
  final double total;
  final DateTime createdAt;
  final String? storeId;
  final String? storeName;
  final String? userId;

  factory StaffOrder.fromMap(Map<String, dynamic> data) {
    return StaffOrder(
      id: data['id'] as String,
      status: data['status'] as String? ?? 'received',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(data['created_at'] as String),
      storeId: data['store_id'] as String?,
      storeName: data['store_name'] as String?,
      userId: data['user_id'] as String?,
    );
  }
}

class StaffOrderItem {
  StaffOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  factory StaffOrderItem.fromMap(Map<String, dynamic> data) {
    return StaffOrderItem(
      id: data['id'] as String,
      name: data['name'] as String,
      quantity: data['quantity'] as int,
      unitPrice: (data['unit_price'] as num).toDouble(),
    );
  }
}

class StaffOrdersService {
  Stream<List<StaffOrder>> streamOrders({String? storeId}) {
    final query = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
    return query.map((rows) {
      final mapped = rows
          .map((row) => StaffOrder.fromMap(row as Map<String, dynamic>))
          .toList();
      if (storeId == null || storeId.isEmpty) {
        return mapped;
      }
      return mapped
          .where(
            (order) => (order.storeId ?? '') == storeId,
          )
          .toList();
    });
  }

  Future<List<StaffOrder>> fetchCompletedOrders({String? storeId}) async {
    var query = supabase.from('orders').select().eq('status', 'completed');
    if (storeId != null && storeId.isNotEmpty) {
      query = query.eq('store_id', storeId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((row) => StaffOrder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<StaffOrderItem>> fetchOrderItems(String orderId) async {
    final response =
        await supabase.from('order_items').select().eq('order_id', orderId);
    return (response as List<dynamic>)
        .map((row) => StaffOrderItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(String orderId, String status) async {
    await supabase.from('orders').update({'status': status}).eq('id', orderId);
  }
}
