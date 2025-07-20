import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/odoo_config.dart';
import '../models/product.dart';
import './supabase_service.dart';

class OdooApiService {
  static final OdooApiService _instance = OdooApiService._internal();
  factory OdooApiService() => _instance;
  OdooApiService._internal();

  final Dio _dio = Dio();
  final SupabaseService _supabaseService = SupabaseService();
  String? _sessionId;
  OdooConfig? _currentConfig;

  // Initialize with configuration
  Future<void> initialize(OdooConfig config) async {
    _currentConfig = config;
    _dio.options = BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        });
  }

  // Authenticate with Odoo
  Future<bool> authenticate() async {
    if (_currentConfig == null) throw Exception('Odoo configuration not set');

    try {
      final client = await _supabaseService.client;
      final response = await _dio
          .post('${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy',
              options: Options(headers: {
                'Authorization': 'Bearer ${_supabaseService.supabaseKey}',
                'Content-Type': 'application/json',
              }),
              data: {
            'odoo_endpoint': '/web/session/authenticate',
            'data': {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'db': _currentConfig!.database,
                'login': _currentConfig!.username,
                'password': _currentConfig!.password,
              }
            },
          });

      if (response.statusCode == 200 && response.data['session_id'] != null) {
        _sessionId = response.data['session_id'];
        await _logOperation('authenticate', 'auth', null, null, 'success',
            response.data, response.data);
        return true;
      }

      await _logOperation(
          'authenticate', 'auth', null, null, 'error', null, response.data);
      return false;
    } catch (e) {
      await _logOperation('authenticate', 'auth', null, null, 'error', null,
          {'error': e.toString()});
      if (kDebugMode) print('Odoo authentication failed: $e');
      return false;
    }
  }

  // Fetch products from Odoo
  Future<List<Map<String, dynamic>>> getProducts() async {
    if (_sessionId == null && !await authenticate()) {
      throw Exception('Authentication failed');
    }

    try {
      final client = await _supabaseService.client;
      final response = await _dio
          .post('${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy',
              options: Options(headers: {
                'Authorization': 'Bearer ${_supabaseService.supabaseKey}',
                'Content-Type': 'application/json',
              }),
              data: {
            'odoo_endpoint': '/web/dataset/call_kw',
            'data': {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'model': 'product.template',
                'method': 'search_read',
                'args': [[]],
                'kwargs': {}
              }
            },
            'session_id': _sessionId,
          });

      if (response.statusCode == 200 && response.data['result'] != null) {
        final products =
            List<Map<String, dynamic>>.from(response.data['result']);
        await _logOperation('fetch', 'product', null, null, 'success',
            {'count': products.length}, response.data);
        return products;
      }

      await _logOperation(
          'fetch', 'product', null, null, 'error', null, response.data);
      return [];
    } catch (e) {
      await _logOperation('fetch', 'product', null, null, 'error', null,
          {'error': e.toString()});
      if (kDebugMode) print('Failed to fetch products from Odoo: $e');
      return [];
    }
  }

  // Create product in Odoo
  Future<int?> createProduct(Product product, String sellerId) async {
    if (_sessionId == null && !await authenticate()) {
      throw Exception('Authentication failed');
    }

    try {
      final client = await _supabaseService.client;

      // Get seller information
      final sellerData = await client
          .from('user_profiles')
          .select('full_name, business_name')
          .eq('id', sellerId)
          .single();

      final productData = {
        'name': product.name,
        'list_price': product.price,
        'seller_id': sellerId,
        'state': 'pending',
        'seller_name': sellerData['business_name'] ?? sellerData['full_name'],
        'seller_uid': sellerId,
        'default_code':
            '${product.category.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
        'meat_type': product.category,
        'description': product.description,
        'categ_id': 1, // Default category ID
      };

      final response = await _dio
          .post('${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy',
              options: Options(headers: {
                'Authorization': 'Bearer ${_supabaseService.supabaseKey}',
                'Content-Type': 'application/json',
              }),
              data: {
            'odoo_endpoint': '/web/dataset/call_kw',
            'data': {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'model': 'product.template',
                'method': 'create',
                'args': [productData]
              }
            },
            'session_id': _sessionId,
          });

      if (response.statusCode == 200 && response.data['result'] != null) {
        final odooProductId = response.data['result'] as int;
        await _logOperation('create', 'product', product.id, odooProductId,
            'success', productData, response.data);
        return odooProductId;
      }

      await _logOperation('create', 'product', product.id, null, 'error',
          productData, response.data);
      return null;
    } catch (e) {
      await _logOperation('create', 'product', product.id, null, 'error', null,
          {'error': e.toString()});
      if (kDebugMode) print('Failed to create product in Odoo: $e');
      return null;
    }
  }

  // Sync products between local and Odoo
  Future<List<Map<String, dynamic>>> syncProductsToLocal(
      List<Product> localProducts, List<String> fieldsToSync) async {
    final odooProducts = await getProducts();
    final syncResults = <Map<String, dynamic>>[];

    for (final odooProduct in odooProducts) {
      bool needsUpdate = false;
      final localProduct = localProducts.firstWhere(
          (p) => p.name == odooProduct['name'],
          orElse: () => Product(
              id: '',
              name: '',
              description: '',
              price: 0.0,
              category: '',
              unit: '',
              isAvailable: false,
              sellerId: '',
              stockQuantity: 0,
              minimumOrderQuantity: 1,
              isApproved: false,
              documentUrls: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now()));

      if (localProduct.id!.isNotEmpty) {
        // Check if update is needed
        for (final field in fieldsToSync) {
          switch (field) {
            case 'list_price':
              if (localProduct.price != (odooProduct['list_price'] ?? 0.0)) {
                needsUpdate = true;
              }
              break;
            case 'name':
              if (localProduct.name != (odooProduct['name'] ?? '')) {
                needsUpdate = true;
              }
              break;
          }
        }

        syncResults.add({
          'local_id': localProduct.id,
          'odoo_id': odooProduct['id'],
          'odoo_name': odooProduct['name'],
          'odoo_price': odooProduct['list_price'],
          'needs_update': needsUpdate,
        });
      }
    }

    return syncResults;
  }

  // Log operation to database
  Future<void> _logOperation(
      String operationType,
      String entityType,
      String? localId,
      int? odooId,
      String status,
      Map<String, dynamic>? requestPayload,
      Map<String, dynamic>? responsePayload) async {
    try {
      final client = await _supabaseService.client;
      await client.from('odoo_sync_logs').insert({
        'operation_type': operationType,
        'entity_type': entityType,
        'local_id': localId,
        'odoo_id': odooId,
        'status': status,
        'request_payload': requestPayload,
        'response_payload': responsePayload,
      });
    } catch (e) {
      if (kDebugMode) print('Failed to log operation: $e');
    }
  }

  // Clear session
  void clearSession() {
    _sessionId = null;
  }

  Future<Map<String, dynamic>> _makeProxyRequest(
      String endpoint, Map<String, dynamic> data) async {
    final client = await _supabaseService.client;
    final response = await http.post(
        Uri.parse(
            '${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseService.supabaseKey}',
        },
        body: json.encode({
          'endpoint': endpoint,
          'data': data,
        }));

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _makeAuthenticatedRequest(
      String endpoint, Map<String, dynamic> data) async {
    final client = await _supabaseService.client;
    final response = await http.post(
        Uri.parse(
            '${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseService.supabaseKey}',
        },
        body: json.encode({
          'endpoint': endpoint,
          'data': data,
          'session_id': _sessionId,
        }));

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _makeBatchRequest(
      List<Map<String, dynamic>> requests) async {
    final client = await _supabaseService.client;
    final response = await http.post(
        Uri.parse(
            '${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseService.supabaseKey}',
        },
        body: json.encode({
          'batch_requests': requests,
          'session_id': _sessionId,
        }));

    return json.decode(response.body);
  }
}
