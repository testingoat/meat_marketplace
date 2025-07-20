class Product {
  final String? id;
  final String? sellerId;
  final String name;
  final String? description;
  final String category;
  final double price;
  final String unit;
  final int stockQuantity;
  final int minimumOrderQuantity;
  final bool isAvailable;
  final String? nutritionalInfo;
  final String? preparationInstructions;
  final String? storageInstructions;
  final List<String>? imageUrls;
  final List<String>? documentUrls;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    this.sellerId,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    required this.minimumOrderQuantity,
    required this.isAvailable,
    this.nutritionalInfo,
    this.preparationInstructions,
    this.storageInstructions,
    this.imageUrls,
    this.documentUrls,
    required this.isApproved,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      sellerId: json['seller_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      stockQuantity: json['stock_quantity'] as int,
      minimumOrderQuantity: json['minimum_order_quantity'] as int,
      isAvailable: json['is_available'] as bool,
      nutritionalInfo: json['nutritional_info'] as String?,
      preparationInstructions: json['preparation_instructions'] as String?,
      storageInstructions: json['storage_instructions'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : (json['images'] != null
              ? List<String>.from(json['images'] as List)
              : null),
      documentUrls: json['document_urls'] != null
          ? List<String>.from(json['document_urls'] as List)
          : (json['documents'] != null
              ? List<String>.from(json['documents'] as List)
              : null),
      isApproved: json['is_approved'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'minimum_order_quantity': minimumOrderQuantity,
      'is_available': isAvailable,
      'nutritional_info': nutritionalInfo,
      'preparation_instructions': preparationInstructions,
      'storage_instructions': storageInstructions,
      'image_urls': imageUrls,
      'document_urls': documentUrls,
      'is_approved': isApproved,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    String? category,
    double? price,
    String? unit,
    int? stockQuantity,
    int? minimumOrderQuantity,
    bool? isAvailable,
    String? nutritionalInfo,
    String? preparationInstructions,
    String? storageInstructions,
    List<String>? imageUrls,
    List<String>? documentUrls,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      preparationInstructions:
          preparationInstructions ?? this.preparationInstructions,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
