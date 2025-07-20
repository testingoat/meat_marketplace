import './product.dart';

class Order {
  final String id;
  final String orderNumber;
  final String buyerId;
  final String sellerId;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryPincode;
  final String? customerPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final bool? syncedToOdoo;
  final String? odooOrderId;

  Order({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryPincode,
    this.customerPhone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.syncedToOdoo,
    this.odooOrderId,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: map['status'] as String,
      deliveryAddress: map['delivery_address'] as String,
      deliveryCity: map['delivery_city'] as String?,
      deliveryState: map['delivery_state'] as String?,
      deliveryPincode: map['delivery_pincode'] as String?,
      customerPhone: map['customer_phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: [], // Items loaded separately
      syncedToOdoo: map['synced_to_odoo'] as bool?,
      odooOrderId: map['odoo_order_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_amount': totalAmount,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_city': deliveryCity,
      'delivery_state': deliveryState,
      'delivery_pincode': deliveryPincode,
      'customer_phone': customerPhone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_to_odoo': syncedToOdoo,
      'odoo_order_id': odooOrderId,
    };
  }

  Order copyWith({
    String? status,
    String? deliveryAddress,
    String? deliveryCity,
    String? deliveryState,
    String? deliveryPincode,
    String? customerPhone,
    String? notes,
    List<OrderItem>? items,
    bool? syncedToOdoo,
    String? odooOrderId,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      buyerId: buyerId,
      sellerId: sellerId,
      totalAmount: totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryState: deliveryState ?? this.deliveryState,
      deliveryPincode: deliveryPincode ?? this.deliveryPincode,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      items: items ?? this.items,
      syncedToOdoo: syncedToOdoo ?? this.syncedToOdoo,
      odooOrderId: odooOrderId ?? this.odooOrderId,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;
  final Product? product; // Optional product details

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    this.product,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      product:
          map['products'] != null ? Product.fromJson(map['products']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
