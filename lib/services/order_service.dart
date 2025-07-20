import '../models/order.dart';
import './supabase_service.dart';

class OrderService {
  final SupabaseService _supabaseService = SupabaseService();

  // Get orders for seller
  Future<List<Order>> getSellerOrders({
    String? status,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final client = await _supabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var query = client
          .from('orders')
          .select('*, order_items(*, products(name))')
          .eq('seller_id', userId);

      if (status != null && status != 'All') {
        query = query.eq('status', status.toLowerCase());
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
            'order_number.ilike.%$searchQuery%,customer_phone.ilike.%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((orderData) {
        final order = Order.fromMap(orderData);
        final items = (orderData['order_items'] as List?)
                ?.map((itemData) => OrderItem.fromMap(itemData))
                .toList() ??
            [];

        return order.copyWith(items: items);
      }).toList();
    } catch (error) {
      throw Exception('Failed to get orders: $error');
    }
  }

  // Get orders for buyer
  Future<List<Order>> getBuyerOrders({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final client = await _supabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var query = client
          .from('orders')
          .select('*, order_items(*, products(name))')
          .eq('buyer_id', userId);

      if (status != null && status != 'All') {
        query = query.eq('status', status.toLowerCase());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((orderData) {
        final order = Order.fromMap(orderData);
        final items = (orderData['order_items'] as List?)
                ?.map((itemData) => OrderItem.fromMap(itemData))
                .toList() ??
            [];

        return order.copyWith(items: items);
      }).toList();
    } catch (error) {
      throw Exception('Failed to get buyer orders: $error');
    }
  }

  // Get single order with details
  Future<Order?> getOrder(String orderId) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('id', orderId)
          .single();

      final order = Order.fromMap(response);
      final items = (response['order_items'] as List?)
              ?.map((itemData) => OrderItem.fromMap(itemData))
              .toList() ??
          [];

      return order.copyWith(items: items);
    } catch (error) {
      throw Exception('Failed to get order: $error');
    }
  }

  // Create new order
  Future<Order> createOrder({
    required String sellerId,
    required List<OrderItem> items,
    required String deliveryAddress,
    required String customerPhone,
    String? deliveryCity,
    String? deliveryState,
    String? deliveryPincode,
    String? notes,
  }) async {
    try {
      final client = await _supabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate total amount
      final totalAmount =
          items.fold<double>(0, (sum, item) => sum + item.totalPrice);

      // Generate order number
      final orderNumberResponse = await client.rpc('generate_order_number');
      final orderNumber = orderNumberResponse as String;

      // Create order
      final orderData = {
        'order_number': orderNumber,
        'buyer_id': userId,
        'seller_id': sellerId,
        'total_amount': totalAmount,
        'delivery_address': deliveryAddress,
        'customer_phone': customerPhone,
        'delivery_city': deliveryCity,
        'delivery_state': deliveryState,
        'delivery_pincode': deliveryPincode,
        'notes': notes,
        'status': 'pending',
      };

      final orderResponse =
          await client.from('orders').insert(orderData).select().single();

      final order = Order.fromMap(orderResponse);

      // Create order items
      final itemsData = items
          .map((item) => {
                'order_id': order.id,
                'product_id': item.productId,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'total_price': item.totalPrice,
              })
          .toList();

      await client.from('order_items').insert(itemsData);

      return order.copyWith(items: items);
    } catch (error) {
      throw Exception('Failed to create order: $error');
    }
  }

  // Update order status
  Future<Order> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('orders')
          .update({
            'status': newStatus.toLowerCase(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

      return Order.fromMap(response);
    } catch (error) {
      throw Exception('Failed to update order status: $error');
    }
  }

  // Get order statistics for seller
  Future<Map<String, dynamic>> getSellerOrderStats(String sellerId) async {
    try {
      final client = await _supabaseService.client;

      // Get today's orders
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
      final todayResponse = await client
          .from('orders')
          .select()
          .eq('seller_id', sellerId)
          .gte('created_at', todayStart.toIso8601String())
          .count();

      // Get pending orders
      final pendingResponse = await client
          .from('orders')
          .select()
          .eq('seller_id', sellerId)
          .eq('status', 'pending')
          .count();

      // Get this month's revenue
      final monthStart =
          DateTime.now().copyWith(day: 1, hour: 0, minute: 0, second: 0);
      final revenueResponse = await client
          .from('orders')
          .select('total_amount')
          .eq('seller_id', sellerId)
          .gte('created_at', monthStart.toIso8601String())
          .not('status', 'eq', 'cancelled');

      double monthlyRevenue = 0;
      monthlyRevenue = revenueResponse.fold(
          0,
          (sum, order) =>
              sum + ((order['total_amount'] as num?)?.toDouble() ?? 0));

      return {
        'todays_orders': todayResponse.count ?? 0,
        'pending_orders': pendingResponse.count ?? 0,
        'monthly_revenue': monthlyRevenue,
      };
    } catch (error) {
      throw Exception('Failed to get order stats: $error');
    }
  }

  // Get recent orders for dashboard
  Future<List<Order>> getRecentOrders({
    required String sellerId,
    int limit = 5,
  }) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('orders')
          .select('*, order_items(*, products(name))')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((orderData) {
        final order = Order.fromMap(orderData);
        final items = (orderData['order_items'] as List?)
                ?.map((itemData) => OrderItem.fromMap(itemData))
                .toList() ??
            [];

        return order.copyWith(items: items);
      }).toList();
    } catch (error) {
      throw Exception('Failed to get recent orders: $error');
    }
  }

  // Get all orders (for sync operations)
  Future<List<Order>> getOrders({
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final client = await _supabaseService.client;

      var query =
          client.from('orders').select('*, order_items(*, products(name))');

      if (status != null && status != 'All') {
        query = query.eq('status', status.toLowerCase());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((orderData) {
        final order = Order.fromMap(orderData);
        final items = (orderData['order_items'] as List?)
                ?.map((itemData) => OrderItem.fromMap(itemData))
                .toList() ??
            [];

        return order.copyWith(items: items);
      }).toList();
    } catch (error) {
      throw Exception('Failed to get orders: $error');
    }
  }

  // Update order with additional fields
  Future<Order> updateOrder(Order order) async {
    try {
      final client = await _supabaseService.client;

      final updateData = order.toMap();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('orders')
          .update(updateData)
          .eq('id', order.id)
          .select()
          .single();

      return Order.fromMap(response);
    } catch (error) {
      throw Exception('Failed to update order: $error');
    }
  }
}
