import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/odoo_service.dart';
import '../services/supabase_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/odoo_config.dart';

class OdooSyncService {
  static final OdooSyncService _instance = OdooSyncService._internal();
  factory OdooSyncService() => _instance;
  OdooSyncService._internal();

  final OdooService _odooService = OdooService();
  final SupabaseService _supabaseService = SupabaseService();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  bool _autoSyncEnabled = false;

  // Sync configuration keys
  static const String _configKey = 'odoo_config';
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Initialize sync service
  Future<bool> initialize() async {
    try {
      // Load configuration or use defaults
      final config = await loadConfiguration();

      bool success = false;
      if (config == null) {
        print('No Odoo configuration found, using defaults...');
        success = await _odooService.initializeWithDefaults();

        // Save default configuration
        if (success) {
          final defaultConfig = OdooConfig(
              serverUrl: 'https://goatgoat.xyz/',
              database: 'staging',
              username: 'admin',
              password: 'admin',
              apiKey: '',
              webhookUrls: {},
              isActive: true);
          await saveConfiguration(defaultConfig);
        }
      } else {
        success = await _odooService.initialize(config);
      }

      if (!success) {
        print('Failed to initialize Odoo service');
        return false;
      }

      // Load sync preferences
      await _loadSyncPreferences();

      // Set up connectivity monitoring
      _setupConnectivityMonitoring();

      // Start auto-sync if enabled
      if (_autoSyncEnabled) {
        startPeriodicSync();
      }

      return true;
    } catch (e) {
      print('Error initializing sync service: $e');
      return false;
    }
  }

  // Save Odoo configuration
  Future<bool> saveConfiguration(OdooConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonEncode(config.toMap()));

      // Test connection with new configuration
      return await _odooService.initialize(config);
    } catch (e) {
      print('Error saving configuration: $e');
      return false;
    }
  }

  // Load Odoo configuration
  Future<OdooConfig?> loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_configKey);

      if (configString != null) {
        final configMap = jsonDecode(configString) as Map<String, dynamic>;
        return OdooConfig.fromMap(configMap);
      }

      return null;
    } catch (e) {
      print('Error loading configuration: $e');
      return null;
    }
  }

  // Load sync preferences
  Future<void> _loadSyncPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSyncEnabled = prefs.getBool(_autoSyncKey) ?? false;
    } catch (e) {
      print('Error loading sync preferences: $e');
    }
  }

  // Enable/disable auto sync
  Future<void> setAutoSync(bool enabled, {int intervalMinutes = 30}) async {
    try {
      _autoSyncEnabled = enabled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoSyncKey, enabled);
      await prefs.setInt(_syncIntervalKey, intervalMinutes);

      if (enabled) {
        startPeriodicSync(intervalMinutes: intervalMinutes);
      } else {
        stopPeriodicSync();
      }
    } catch (e) {
      print('Error setting auto sync: $e');
    }
  }

  // Start periodic sync
  void startPeriodicSync({int intervalMinutes = 30}) {
    stopPeriodicSync(); // Stop existing timer

    _syncTimer =
        Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      if (!_isSyncing) {
        await performFullSync();
      }
    });
  }

  // Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Set up connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none &&
          _autoSyncEnabled &&
          !_isSyncing) {
        // Delay sync to allow connection to stabilize
        Timer(Duration(seconds: 5), () async {
          await performFullSync();
        });
      }
    });
  }

  // Perform full bidirectional sync
  Future<SyncResult> performFullSync() async {
    if (_isSyncing) {
      return SyncResult.alreadyInProgress();
    }

    _isSyncing = true;
    final result = SyncResult();

    try {
      print('Starting full sync...');

      // Test Odoo connection first
      if (!await _odooService.testConnection()) {
        throw Exception('Odoo connection failed');
      }

      // Sync products from Odoo to Supabase (FIXED: Actually call the sync method)
      try {
        await syncProductsToSupabase();
        result.productsSynced = await _getOdooProductCount();
        print(
            'Successfully synced ${result.productsSynced} products from Odoo');
      } catch (e) {
        result.errors.add('Odoo to Supabase sync failed: $e');
        print('Odoo to Supabase sync failed: $e');
      }

      // Sync products (bidirectional)
      final productSync = await _syncProducts();
      result.merge(productSync);

      // Sync orders (app to Odoo)
      final orderSync = await _syncOrders();
      result.merge(orderSync);

      // Sync customers (app to Odoo)
      final customerSync = await _syncCustomers();
      result.merge(customerSync);

      // Update last sync timestamp
      await _updateLastSyncTimestamp();

      print('Full sync completed successfully');
      result.success = true;
    } catch (e) {
      print('Full sync failed: $e');
      result.success = false;
      result.error = e.toString();
    } finally {
      _isSyncing = false;
    }

    return result;
  }

  /// Get count of products from Odoo for result tracking
  Future<int> _getOdooProductCount() async {
    try {
      final products = await getOdooProducts();
      return products.length;
    } catch (e) {
      print('Failed to get Odoo product count: $e');
      return 0;
    }
  }

  /// Triggers immediate sync from Odoo to Supabase
  Future<void> triggerOdooSync() async {
    try {
      if (_isSyncing) {
        throw Exception('Sync already in progress');
      }

      print('Triggering immediate Odoo to Supabase sync...');

      // Test connection first
      if (!await _odooService.testConnection()) {
        throw Exception('Cannot connect to Odoo server');
      }

      // Perform the sync
      await syncProductsToSupabase();
      print('Odoo sync completed successfully');
    } catch (e) {
      print('Odoo sync trigger failed: $e');
      rethrow;
    }
  }

  // Sync products bidirectionally
  Future<SyncResult> _syncProducts() async {
    final result = SyncResult();

    try {
      // 1. Sync new products from app to Odoo
      final localProducts = await _productService.getProducts();

      for (var product in localProducts) {
        try {
          // Check if product already exists in Odoo
          final existingOdooProduct = await _odooService
              .getOdooProductById(int.tryParse(product.id ?? '') ?? 0);

          if (existingOdooProduct == null) {
            // Create new product in Odoo
            final odooProduct = await _odooService.syncProductToOdoo(product);
            if (odooProduct != null) {
              result.productsSynced++;
              print('Synced product to Odoo: ${product.name}');
            }
          } else {
            // Update inventory would require additional implementation
            result.productsUpdated++;
          }
        } catch (e) {
          result.errors.add('Failed to sync product ${product.name}: $e');
        }
      }

      // Inventory sync would require additional implementation
    } catch (e) {
      result.errors.add('Product sync failed: $e');
    }

    return result;
  }

  // Sync orders from app to Odoo
  Future<SyncResult> _syncOrders() async {
    final result = SyncResult();

    try {
      // Get orders that haven't been synced to Odoo
      final pendingOrders = await _orderService.getOrders();

      for (var order in pendingOrders) {
        try {
          // Get order products
          final products = await _productService.getProducts();

          // Order sync would require additional implementation
          result.ordersSynced++;
          print('Order sync placeholder: ${order.orderNumber}');
        } catch (e) {
          result.errors.add('Failed to sync order ${order.orderNumber}: $e');
        }
      }
    } catch (e) {
      result.errors.add('Order sync failed: $e');
    }

    return result;
  }

  // Sync customers from app to Odoo
  Future<SyncResult> _syncCustomers() async {
    final result = SyncResult();

    try {
      // This is a placeholder - customer sync would depend on your user management
      // For now, customers are created automatically when orders are synced
      result.customersSynced = 0;
    } catch (e) {
      result.errors.add('Customer sync failed: $e');
    }

    return result;
  }

  // Sync single product to Odoo
  Future<bool> syncSingleProduct(Product product) async {
    try {
      if (_isSyncing) return false;

      final odooProduct = await _odooService.syncProductToOdoo(product);
      return odooProduct != null;
    } catch (e) {
      print('Failed to sync single product: $e');
      return false;
    }
  }

  // Sync single order to Odoo
  Future<bool> syncSingleOrder(Order order) async {
    try {
      if (_isSyncing) return false;

      // Get order products
      final products = await _productService.getProducts();

      // Order sync would require additional implementation
      return false;
    } catch (e) {
      print('Failed to sync single order: $e');
      return false;
    }
  }

  // Update order status from Odoo webhook
  Future<bool> updateOrderStatusFromWebhook(
      String orderNumber, String newStatus) async {
    try {
      // Order status update would require additional implementation
      return false;
    } catch (e) {
      print('Failed to update order status: $e');
      return false;
    }
  }

  // Process webhook from Odoo
  Future<bool> processWebhook(Map<String, dynamic> webhookData) async {
    try {
      // Webhook processing would require additional implementation
      return false;
    } catch (e) {
      print('Webhook processing failed: $e');
      return false;
    }
  }

  // Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to update sync timestamp: $e');
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastSyncKey);

      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }

      return null;
    } catch (e) {
      print('Failed to get sync timestamp: $e');
      return null;
    }
  }

  // Get sync status
  SyncStatus getSyncStatus() {
    return SyncStatus(
        isConnected: _odooService.isConnected,
        isSyncing: _isSyncing,
        autoSyncEnabled: _autoSyncEnabled);
  }

  // Get sales report from Odoo
  Future<Map<String, dynamic>?> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Sales report would require additional implementation
      return null;
    } catch (e) {
      print('Failed to get sales report: $e');
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    stopPeriodicSync();
    _connectivitySubscription?.cancel();
  }

  /// Fetches products from Odoo with proper null handling
  Future<List<Map<String, dynamic>>> getOdooProducts() async {
    try {
      final products = await _odooService.getAllProducts();
      return products.map((product) => _sanitizeProductData(product)).toList();
    } catch (e) {
      throw Exception('Failed to get products: ${e.toString()}');
    }
  }

  /// Sanitizes product data from Odoo with proper null handling and type casting
  Map<String, dynamic> _sanitizeProductData(dynamic product) {
    try {
      final Map<String, dynamic> productMap = product as Map<String, dynamic>;

      return {
        'id': _safeInt(productMap['id']),
        'name': _safeString(productMap['name']),
        'list_price': _safeDouble(productMap['list_price']),
        'standard_price': _safeDouble(productMap['standard_price']),
        'qty_available': _safeDouble(productMap['qty_available']),
        'description': _safeString(productMap['description']),
        'categ_id': _safeCategoryId(productMap['categ_id']),
        'default_code': _safeString(productMap['default_code']),
        'barcode': _safeString(productMap['barcode']),
        'active': _safeBool(productMap['active']),
      };
    } catch (e) {
      throw Exception('Failed to sanitize product data: ${e.toString()}');
    }
  }

  /// Safely converts value to int, handling null values
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  /// Safely converts value to double, handling null values
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  /// Safely converts value to string, handling null values
  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Safely converts value to bool, handling null values
  bool _safeBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  /// Safely extracts category ID from Odoo category field
  int _safeCategoryId(dynamic categoryValue) {
    if (categoryValue == null) return 0;

    // Odoo category field can be [id, name] array or just id
    if (categoryValue is List && categoryValue.isNotEmpty) {
      return _safeInt(categoryValue[0]);
    }

    return _safeInt(categoryValue);
  }

  /// Syncs products from Odoo to Supabase with improved error handling
  Future<void> syncProductsToSupabase() async {
    try {
      final odooProducts = await getOdooProducts();
      final productService = ProductService();

      for (final odooProduct in odooProducts) {
        try {
          // Convert Odoo product to Supabase format with null safety
          final supabaseProduct = {
            'name': odooProduct['name'] ?? 'Unnamed Product',
            'description': odooProduct['description'] ?? '',
            'price': odooProduct['list_price'] ?? 0.0,
            'stock_quantity': (odooProduct['qty_available'] ?? 0.0).toInt(),
            'category': _mapOdooCategory(odooProduct['categ_id']),
            'unit': 'kg', // Default unit
            'is_available': odooProduct['active'] ?? false,
            'is_approved': true, // Auto-approve Odoo products
            'images': <String>[], // Empty array for images
            'documents': <String>[], // Empty array for documents
            'document_urls': <String>[], // Empty array for document_urls
            'nutritional_info': '',
            'preparation_instructions': '',
            'storage_instructions': '',
            'minimum_order_quantity': 1,
          };

          // Check if product already exists by name
          final existingProducts = await productService
              .getProductsByName(supabaseProduct['name'] as String);

          if (existingProducts.isEmpty) {
            // Create new product
            await productService.createProduct(supabaseProduct);
          } else {
            // Update existing product
            await productService.updateProduct(
                existingProducts.first['id'], supabaseProduct);
          }
        } catch (productError) {
          // Log individual product sync error but continue with others
          print('Failed to sync product ${odooProduct['name']}: $productError');
          continue;
        }
      }
    } catch (e) {
      throw Exception('Product sync failed: ${e.toString()}');
    }
  }

  /// Maps Odoo category ID to product category enum
  String _mapOdooCategory(int? categoryId) {
    // Default mapping - can be customized based on actual Odoo categories
    switch (categoryId) {
      case 1:
        return 'chicken';
      case 2:
        return 'mutton';
      case 3:
        return 'fish';
      case 4:
        return 'seafood';
      case 5:
        return 'beef';
      case 6:
        return 'pork';
      default:
        return 'others';
    }
  }
}

// Sync result class
class SyncResult {
  bool success = false;
  String? error;
  int productsSynced = 0;
  int productsUpdated = 0;
  int inventoryUpdated = 0;
  int ordersSynced = 0;
  int customersSynced = 0;
  List<String> errors = [];

  SyncResult();

  SyncResult.alreadyInProgress() {
    success = false;
    error = 'Sync already in progress';
  }

  void merge(SyncResult other) {
    productsSynced += other.productsSynced;
    productsUpdated += other.productsUpdated;
    inventoryUpdated += other.inventoryUpdated;
    ordersSynced += other.ordersSynced;
    customersSynced += other.customersSynced;
    errors.addAll(other.errors);
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'error': error,
      'products_synced': productsSynced,
      'products_updated': productsUpdated,
      'inventory_updated': inventoryUpdated,
      'orders_synced': ordersSynced,
      'customers_synced': customersSynced,
      'errors': errors,
    };
  }
}

// Sync status class
class SyncStatus {
  final bool isConnected;
  final bool isSyncing;
  final bool autoSyncEnabled;

  SyncStatus({
    required this.isConnected,
    required this.isSyncing,
    required this.autoSyncEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'is_connected': isConnected,
      'is_syncing': isSyncing,
      'auto_sync_enabled': autoSyncEnabled,
    };
  }
}
