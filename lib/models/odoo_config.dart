
class OdooConfig {
  final String id;
  final String serverUrl;
  final String database;
  final String username;
  final String password;
  final String apiKey;
  final bool isActive;
  final Map<String, String> webhookUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OdooConfig({
    this.id = '',
    required this.serverUrl,
    required this.database,
    required this.username,
    required this.password,
    required this.apiKey,
    required this.isActive,
    required this.webhookUrls,
    this.createdAt,
    this.updatedAt,
  });

  factory OdooConfig.fromMap(Map<String, dynamic> map) {
    return OdooConfig(
      id: map['id'] as String,
      serverUrl: map['server_url'] as String,
      database: map['database'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      apiKey: map['api_key'] as String,
      isActive: map['is_active'] as bool,
      webhookUrls: Map<String, String>.from(map['webhook_urls'] ?? {}),
      createdAt: map['create_date'] != null
          ? DateTime.parse(map['create_date'])
          : null,
      updatedAt:
          map['write_date'] != null ? DateTime.parse(map['write_date']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_url': serverUrl,
      'database': database,
      'username': username,
      'password': password,
      'api_key': apiKey,
      'is_active': isActive,
      'webhook_urls': webhookUrls,
      'create_date': createdAt?.toIso8601String(),
      'write_date': updatedAt?.toIso8601String(),
    };
  }
}

// Odoo Product Model for ERP Integration
class OdooProduct {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final int? categoryId;
  final String? categoryName;
  final double stockQuantity;
  final String? unit;
  final bool active;
  final String? barcode;
  final String? internalReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? supplierName;
  final String? supplierCode;

  OdooProduct({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    required this.stockQuantity,
    this.unit,
    required this.active,
    this.barcode,
    this.internalReference,
    this.createdAt,
    this.updatedAt,
    this.supplierName,
    this.supplierCode,
  });

  factory OdooProduct.fromMap(Map<String, dynamic> map) {
    return OdooProduct(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['list_price'] ?? map['price'] ?? 0.0).toDouble(),
      categoryId:
          map['categ_id'] is List ? map['categ_id'][0] : map['categ_id'],
      categoryName: map['categ_id'] is List ? map['categ_id'][1] : null,
      stockQuantity: (map['qty_available'] ?? 0.0).toDouble(),
      unit: map['uom_name'] as String?,
      active: map['active'] ?? true,
      barcode: map['barcode'] as String?,
      internalReference: map['default_code'] as String?,
      createdAt: map['create_date'] != null
          ? DateTime.parse(map['create_date'])
          : null,
      updatedAt:
          map['write_date'] != null ? DateTime.parse(map['write_date']) : null,
      supplierName: map['seller_ids'] is List && map['seller_ids'].isNotEmpty
          ? map['seller_ids'][0]['name']
          : null,
      supplierCode: map['seller_ids'] is List && map['seller_ids'].isNotEmpty
          ? map['seller_ids'][0]['product_code']
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'list_price': price,
      'categ_id': categoryId,
      'qty_available': stockQuantity,
      'active': active,
      'barcode': barcode,
      'default_code': internalReference,
    };
  }
}

// Odoo Sale Order Model
class OdooSaleOrder {
  final int? id;
  final String name;
  final int? partnerId;
  final String? partnerName;
  final String? partnerEmail;
  final String? partnerPhone;
  final double amountTotal;
  final String state;
  final DateTime? dateOrder;
  final DateTime? confirmationDate;
  final List<OdooOrderLine> orderLines;
  final String? deliveryAddress;
  final String? notes;

  OdooSaleOrder({
    this.id,
    required this.name,
    this.partnerId,
    this.partnerName,
    this.partnerEmail,
    this.partnerPhone,
    required this.amountTotal,
    required this.state,
    this.dateOrder,
    this.confirmationDate,
    required this.orderLines,
    this.deliveryAddress,
    this.notes,
  });

  factory OdooSaleOrder.fromMap(Map<String, dynamic> map) {
    List<OdooOrderLine> lines = [];
    if (map['order_line'] != null) {
      lines = (map['order_line'] as List)
          .map((line) => OdooOrderLine.fromMap(line))
          .toList();
    }

    return OdooSaleOrder(
      id: map['id'] as int?,
      name: map['name'] as String,
      partnerId:
          map['partner_id'] is List ? map['partner_id'][0] : map['partner_id'],
      partnerName: map['partner_id'] is List ? map['partner_id'][1] : null,
      partnerEmail: map['partner_email'] as String?,
      partnerPhone: map['partner_phone'] as String?,
      amountTotal: (map['amount_total'] ?? 0.0).toDouble(),
      state: map['state'] as String,
      dateOrder:
          map['date_order'] != null ? DateTime.parse(map['date_order']) : null,
      confirmationDate: map['confirmation_date'] != null
          ? DateTime.parse(map['confirmation_date'])
          : null,
      orderLines: lines,
      deliveryAddress: map['partner_shipping_id'] as String?,
      notes: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'partner_id': partnerId,
      'amount_total': amountTotal,
      'state': state,
      'date_order': dateOrder?.toIso8601String(),
      'order_line': orderLines.map((line) => line.toMap()).toList(),
      'note': notes,
    };
  }
}

// Odoo Order Line Model
class OdooOrderLine {
  final int? id;
  final int? productId;
  final String? productName;
  final double quantity;
  final double priceUnit;
  final double priceSubtotal;
  final String? productUom;

  OdooOrderLine({
    this.id,
    this.productId,
    this.productName,
    required this.quantity,
    required this.priceUnit,
    required this.priceSubtotal,
    this.productUom,
  });

  factory OdooOrderLine.fromMap(Map<String, dynamic> map) {
    return OdooOrderLine(
      id: map['id'] as int?,
      productId:
          map['product_id'] is List ? map['product_id'][0] : map['product_id'],
      productName: map['product_id'] is List ? map['product_id'][1] : null,
      quantity: (map['product_uom_qty'] ?? 0.0).toDouble(),
      priceUnit: (map['price_unit'] ?? 0.0).toDouble(),
      priceSubtotal: (map['price_subtotal'] ?? 0.0).toDouble(),
      productUom: map['product_uom'] is List ? map['product_uom'][1] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_uom_qty': quantity,
      'price_unit': priceUnit,
      'price_subtotal': priceSubtotal,
    };
  }
}

// Odoo Customer Model
class OdooCustomer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? street;
  final String? city;
  final String? state;
  final String? zip;
  final String? country;
  final bool isCompany;
  final bool supplier;
  final bool customer;
  final DateTime? createdAt;

  OdooCustomer({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.street,
    this.city,
    this.state,
    this.zip,
    this.country,
    required this.isCompany,
    required this.supplier,
    required this.customer,
    this.createdAt,
  });

  factory OdooCustomer.fromMap(Map<String, dynamic> map) {
    return OdooCustomer(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      state: map['state_id'] is List ? map['state_id'][1] : null,
      zip: map['zip'] as String?,
      country: map['country_id'] is List ? map['country_id'][1] : null,
      isCompany: map['is_company'] ?? false,
      supplier: map['supplier_rank'] != null && map['supplier_rank'] > 0,
      customer: map['customer_rank'] != null && map['customer_rank'] > 0,
      createdAt: map['create_date'] != null
          ? DateTime.parse(map['create_date'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'street': street,
      'city': city,
      'zip': zip,
      'is_company': isCompany,
      'supplier_rank': supplier ? 1 : 0,
      'customer_rank': customer ? 1 : 0,
    };
  }
}
