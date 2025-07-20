import '../models/product.dart';
import './supabase_service.dart';
import './odoo_service.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  final SupabaseService _supabaseService = SupabaseService();
  final OdooService _odooService = OdooService();

  // Get all products (approved and available)
  Future<List<Product>> getProducts({
    String? category,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final client = await _supabaseService.client;

      var query = client
          .from('products')
          .select()
          .eq('is_available', true)
          .eq('is_approved', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (error) {
      throw Exception('Failed to get products: $error');
    }
  }

  // Get products by seller
  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (error) {
      throw Exception('Failed to get seller products: $error');
    }
  }

  // Get single product by ID
  Future<Product?> getProduct(String productId) async {
    try {
      final client = await _supabaseService.client;

      final response =
          await client.from('products').select().eq('id', productId).single();

      return Product.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get product: $error');
    }
  }

  /// Creates a new product with document_urls support
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Add user_id to product data
      productData['user_id'] = userId;
      productData['created_at'] = DateTime.now().toIso8601String();
      productData['updated_at'] = DateTime.now().toIso8601String();

      final client = await _supabaseService.client;
      final response =
          await client.from('products').insert(productData).select().single();

      return response;
    } catch (e) {
      debugPrint('Error creating product: $e');
      rethrow;
    }
  }

  /// Updates an existing product with document_urls support
  Future<Map<String, dynamic>> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      final client = await _supabaseService.client;

      // Add updated_at timestamp
      productData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('products')
          .update(productData)
          .eq('id', productId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update product: $error');
    }
  }

  // Update product with specific parameters
  Future<Product> updateProductDetails({
    required String productId,
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
    List<String>? images,
    List<String>? documents,
  }) async {
    try {
      final client = await _supabaseService.client;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (price != null) updateData['price'] = price;
      if (unit != null) updateData['unit'] = unit;
      if (stockQuantity != null) updateData['stock_quantity'] = stockQuantity;
      if (minimumOrderQuantity != null)
        updateData['minimum_order_quantity'] = minimumOrderQuantity;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (nutritionalInfo != null)
        updateData['nutritional_info'] = nutritionalInfo;
      if (preparationInstructions != null)
        updateData['preparation_instructions'] = preparationInstructions;
      if (storageInstructions != null)
        updateData['storage_instructions'] = storageInstructions;
      if (images != null) updateData['images'] = images;
      if (documents != null) updateData['documents'] = documents;

      final response = await client
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update product: $error');
    }
  }

  // Get products by name for Odoo sync duplicate checking
  Future<List<Map<String, dynamic>>> getProductsByName(String name) async {
    try {
      final client = await _supabaseService.client;

      final response = await client.from('products').select().eq('name', name);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get products by name: $error');
    }
  }

  // Get all products with proper null handling for document_urls
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      // Ensure document_urls is present for all products
      return List<Map<String, dynamic>>.from(response).map((product) {
        if (product['document_urls'] == null) {
          product['document_urls'] = <String>[];
        }
        return product;
      }).toList();
    } catch (error) {
      throw Exception('Failed to get all products: $error');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      final client = await _supabaseService.client;

      await client.from('products').delete().eq('id', productId);
    } catch (error) {
      throw Exception('Failed to delete product: $error');
    }
  }

  // Get product statistics for seller
  Future<Map<String, dynamic>> getSellerProductStats(String sellerId) async {
    try {
      final client = await _supabaseService.client;

      // Get total products count
      final totalResponse = await client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .count();

      // Get active products count
      final activeResponse = await client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_available', true)
          .count();

      // Get low stock products (less than 10)
      final lowStockResponse = await client
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .lt('stock_quantity', 10)
          .count();

      return {
        'total_products': totalResponse.count ?? 0,
        'active_products': activeResponse.count ?? 0,
        'low_stock_products': lowStockResponse.count ?? 0,
      };
    } catch (error) {
      throw Exception('Failed to get product stats: $error');
    }
  }

  // Update product stock quantity
  Future<Product> updateStock(String productId, int newStockQuantity) async {
    try {
      final client = await _supabaseService.client;

      final response = await client
          .from('products')
          .update({
            'stock_quantity': newStockQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update stock: $error');
    }
  }

  Future<void> publishProduct(Product product) async {
    try {
      final client = await _supabaseService.client;

      // Ensure image_urls is properly formatted for database
      final imageUrls = product.imageUrls ?? [];

      // FIXED: Map category to lowercase enum value for database
      final categoryValue = _mapCategoryToEnum(product.category);

      final productData = {
        'name': product.name,
        'description': product.description,
        'category': categoryValue, // Use mapped enum value
        'price': product.price,
        'unit': product.unit,
        'stock_quantity': product.stockQuantity,
        'minimum_order_quantity': product.minimumOrderQuantity,
        'is_available': product.isAvailable,
        'nutritional_info': product.nutritionalInfo,
        'preparation_instructions': product.preparationInstructions,
        'storage_instructions': product.storageInstructions,
        'image_urls': imageUrls,
        'document_urls': product.documentUrls,
        'is_approved': false, // Products need approval
        'seller_id': product.sellerId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Create/Update product in Supabase
      Map<String, dynamic> savedProduct;
      if (product.id != null) {
        // Update existing product
        savedProduct = await client
            .from('products')
            .update(productData)
            .eq('id', product.id!)
            .select()
            .single();
      } else {
        // Create new product
        savedProduct =
            await client.from('products').insert(productData).select().single();
      }

      // IMPLEMENTED: Sync product to Odoo after successful Supabase creation
      await _syncProductToOdoo(Product.fromJson(savedProduct));
    } catch (e) {
      throw Exception('Failed to publish product: $e');
    }
  }

  Future<void> saveDraft(Product product) async {
    try {
      final client = await _supabaseService.client;

      // Ensure image_urls is properly formatted for database
      final imageUrls = product.imageUrls ?? [];

      // FIXED: Map category to lowercase enum value for database
      final categoryValue = _mapCategoryToEnum(product.category);

      final draftData = {
        'name': product.name,
        'description': product.description,
        'category': categoryValue, // Use mapped enum value
        'price': product.price,
        'unit': product.unit,
        'stock_quantity': product.stockQuantity,
        'minimum_order_quantity': product.minimumOrderQuantity,
        'is_available': false, // Drafts are not available for sale
        'nutritional_info': product.nutritionalInfo,
        'preparation_instructions': product.preparationInstructions,
        'storage_instructions': product.storageInstructions,
        'image_urls': imageUrls,
        'document_urls': product.documentUrls,
        'is_approved': false,
        'seller_id': product.sellerId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (product.id != null) {
        // Update existing draft
        await client
            .from('products')
            .update(draftData)
            .eq('id', product.id!)
            .select()
            .single();
      } else {
        // Create new draft
        await client.from('products').insert(draftData).select().single();
      }
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  // Helper method to map category to database enum value
  String _mapCategoryToEnum(String category) {
    // Handle both lowercase enum values and user-friendly labels
    switch (category.toLowerCase()) {
      case 'chicken':
        return 'chicken';
      case 'mutton':
        return 'mutton';
      case 'fish':
        return 'fish';
      case 'seafood':
        return 'seafood';
      case 'pork':
        return 'pork';
      case 'beef':
        return 'beef';
      case 'others':
        return 'others';
      // Fallback for any unmapped values
      default:
        return 'others';
    }
  }

  // Private method to sync product to Odoo
  Future<void> _syncProductToOdoo(Product product) async {
    try {
      // Initialize Odoo service if not already initialized
      if (!_odooService.isConnected) {
        debugPrint('Initializing Odoo connection...');
        final initialized = await _odooService.initializeWithDefaults();
        if (!initialized) {
          debugPrint('Failed to initialize Odoo connection - skipping sync');
          return; // Don't fail the entire product creation if Odoo sync fails
        }
      }

      // Sync product to Odoo using the working integration structure
      final odooProduct = await _odooService.syncProductToOdoo(product);

      if (odooProduct != null) {
        debugPrint(
            'Product successfully synced to Odoo with ID: ${odooProduct.id}');
      } else {
        debugPrint('Product sync to Odoo failed - product created in app only');
      }
    } catch (e) {
      // Log error but don't fail the entire product creation
      debugPrint('Odoo sync error (product still created in app): $e');
    }
  }
}
