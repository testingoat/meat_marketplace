import 'package:flutter/foundation.dart';

import '../models/odoo_config.dart';
import '../models/product.dart';
import './odoo_api_service.dart';
import './product_service.dart';
import './supabase_service.dart';

class OdooSyncManager {
  static final OdooSyncManager _instance = OdooSyncManager._internal();
  factory OdooSyncManager() => _instance;
  OdooSyncManager._internal();

  final OdooApiService _odooService = OdooApiService();
  final ProductService _productService = ProductService();
  final SupabaseService _supabaseService = SupabaseService();

  bool _syncInProgress = false;
  bool get syncInProgress => _syncInProgress;

  // Initialize with user's Odoo configuration
  Future<bool> initializeWithConfig(String userId) async {
    try {
      final client = await _supabaseService.client;
      final configData = await client
          .from('odoo_configurations')
          .select()
          .eq('user_id', userId)
          .eq('sync_enabled', true)
          .maybeSingle();

      if (configData != null) {
        final config = OdooConfig(
          serverUrl: configData['server_url'] as String,
          database: configData['database'] as String,
          username: configData['username'] as String,
          password: configData['password'] as String,
          apiKey: configData['api_key'] as String? ?? '',
          isActive: configData['is_active'] as bool? ?? false,
          webhookUrls:
              Map<String, String>.from(configData['webhook_urls'] ?? {}),
        );
        await _odooService.initialize(config);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Failed to initialize Odoo config: $e');
      return false;
    }
  }

  // Full product sync process
  Future<Map<String, dynamic>> syncProducts(String userId) async {
    if (_syncInProgress) {
      return {'success': false, 'message': 'Sync already in progress'};
    }

    _syncInProgress = true;
    try {
      // Step 1: Initialize configuration
      if (!await initializeWithConfig(userId)) {
        return {'success': false, 'message': 'Odoo configuration not found'};
      }

      // Step 2: Authenticate with Odoo
      if (!await _odooService.authenticate()) {
        return {'success': false, 'message': 'Odoo authentication failed'};
      }

      // Step 3: Fetch products from both sources
      final localProducts = await _productService.getProducts();
      final syncResults = await _odooService
          .syncProductsToLocal(localProducts, ['name', 'list_price', 'uom_id']);

      // Step 4: Update local products with Odoo data
      int updatedCount = 0;
      for (final result in syncResults) {
        if (result['needs_update'] == true) {
          await _updateLocalProduct(result);
          await _updateProductMapping(
              result['local_id'], result['odoo_id'], 'synced');
          updatedCount++;
        }
      }

      // Step 5: Update sync timestamp
      await _updateLastSyncTime(userId);

      return {
        'success': true,
        'message': 'Sync completed successfully',
        'updated_count': updatedCount,
        'total_synced': syncResults.length,
      };
    } catch (e) {
      if (kDebugMode) print('Sync failed: $e');
      return {'success': false, 'message': 'Sync failed: $e'};
    } finally {
      _syncInProgress = false;
    }
  }

  // Push local product to Odoo
  Future<Map<String, dynamic>> pushProductToOdoo(
      Product product, String userId) async {
    try {
      // Initialize if needed
      if (!await initializeWithConfig(userId)) {
        return {'success': false, 'message': 'Odoo configuration not found'};
      }

      // Create product in Odoo
      final odooProductId = await _odooService.createProduct(product, userId);

      if (odooProductId != null) {
        // Create mapping
        await _updateProductMapping(product.id!, odooProductId, 'synced');

        return {
          'success': true,
          'message': 'Product successfully synced to Odoo',
          'odoo_id': odooProductId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create product in Odoo'
        };
      }
    } catch (e) {
      if (kDebugMode) print('Push to Odoo failed: $e');
      return {'success': false, 'message': 'Push failed: $e'};
    }
  }

  // Get sync status for products
  Future<List<Map<String, dynamic>>> getSyncStatus(String userId) async {
    try {
      final client = await _supabaseService.client;
      final mappings = await client.from('odoo_product_mappings').select('''
            id,
            local_product_id,
            odoo_product_id,
            sync_status,
            last_synced_at,
            products!inner(name, seller_id)
          ''').eq('products.seller_id', userId);

      return List<Map<String, dynamic>>.from(mappings);
    } catch (e) {
      if (kDebugMode) print('Failed to get sync status: $e');
      return [];
    }
  }

  // Get sync logs
  Future<List<Map<String, dynamic>>> getSyncLogs(String userId) async {
    try {
      final client = await _supabaseService.client;
      final logs = await client
          .from('odoo_sync_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      if (kDebugMode) print('Failed to get sync logs: $e');
      return [];
    }
  }

  // Private helper methods
  Future<void> _updateLocalProduct(Map<String, dynamic> syncResult) async {
    try {
      final client = await _supabaseService.client;
      await client.from('products').update({
        'price': syncResult['odoo_price'],
        'name': syncResult['odoo_name'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', syncResult['local_id']);
    } catch (e) {
      if (kDebugMode) print('Failed to update local product: $e');
    }
  }

  Future<void> _updateProductMapping(
      String localProductId, int odooProductId, String status) async {
    try {
      final client = await _supabaseService.client;
      await client.rpc('upsert_odoo_product_mapping', params: {
        'p_local_product_id': localProductId,
        'p_odoo_product_id': odooProductId,
        'p_sync_status': status,
      });
    } catch (e) {
      if (kDebugMode) print('Failed to update product mapping: $e');
    }
  }

  Future<void> _updateLastSyncTime(String userId) async {
    try {
      final client = await _supabaseService.client;
      await client
          .from('odoo_configurations')
          .update({'last_sync_at': DateTime.now().toIso8601String()}).eq(
              'user_id', userId);
    } catch (e) {
      if (kDebugMode) print('Failed to update sync time: $e');
    }
  }
}
