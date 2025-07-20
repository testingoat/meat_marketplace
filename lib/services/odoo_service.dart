import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/odoo_config.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class OdooService {
  static final OdooService _instance = OdooService._internal();
  factory OdooService() => _instance;
  OdooService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  OdooConfig? _config;
  int? _userId;
  String? _sessionId;
  String? _edgeFunctionUrl;

  // Initialize Odoo connection with configuration
  Future<bool> initialize(OdooConfig config) async {
    try {
      _config = config;

      // Ensure Supabase is initialized first
      await _supabaseService.client;

      // Set up Edge Function URL for Supabase
      _edgeFunctionUrl =
          '${_supabaseService.supabaseUrl}/functions/v1/odoo-api-proxy';

      return await _authenticate();
    } catch (e) {
      print('Odoo initialization failed: $e');
      return false;
    }
  }

  // Initialize with default configuration
  Future<bool> initializeWithDefaults() async {
    final defaultConfig = OdooConfig(
        serverUrl: 'https://goatgoat.xyz/',
        database: 'staging',
        username: 'admin',
        password: 'admin',
        apiKey: '',
        webhookUrls: {},
        isActive: true);

    return await initialize(defaultConfig);
  }

  // Authenticate with Odoo server through Edge Function
  Future<bool> _authenticate() async {
    if (_config == null || _edgeFunctionUrl == null) return false;

    try {
      final response = await http.post(Uri.parse(_edgeFunctionUrl!),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${_supabaseService.currentClient.auth.currentSession?.accessToken}',
          },
          body: jsonEncode({
            'odoo_endpoint': '/web/session/authenticate',
            'data': {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'db': _config!.database,
                'login': _config!.username,
                'password': _config!.password,
              }
            }
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['uid'] != null) {
          _userId = data['result']['uid'];
          _sessionId = data['result']['session_id'];
          print('Odoo authentication successful. User ID: $_userId');
          return true;
        } else {
          print('Authentication failed: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        print('HTTP error during authentication: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return false;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  // Generic method to call Odoo API through Edge Function
  Future<Map<String, dynamic>?> _callOdooAPI(
      String model, String method, List<dynamic> args,
      {Map<String, dynamic>? kwargs}) async {
    if (_config == null || _userId == null || _edgeFunctionUrl == null) {
      throw Exception('Odoo not initialized. Call initialize() first.');
    }

    try {
      final response = await http.post(Uri.parse(_edgeFunctionUrl!),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${_supabaseService.currentClient.auth.currentSession?.accessToken}',
          },
          body: jsonEncode({
            'odoo_endpoint': '/web/dataset/call_kw',
            'data': {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'model': model,
                'method': method,
                'args': args,
                'kwargs': kwargs ?? {},
              }
            },
            'session_id': _sessionId,
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          throw Exception('Odoo API error: ${data['error']['message']}');
        }
        return data;
      } else {
        throw Exception(
            'HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Odoo API call error: $e');
      rethrow;
    }
  }

  // PRODUCT SYNCHRONIZATION METHODS

  // Sync product from app to Odoo
  Future<OdooProduct?> syncProductToOdoo(Product product) async {
    try {
      if (_config == null || _edgeFunctionUrl == null) {
        await initializeWithDefaults();
      }

      // IMPLEMENTED: Use the exact payload structure provided by user for Odoo product creation
      final odooProductData = {
        'name': product.name,
        'list_price': product.price,
        'seller_id': product.sellerId ?? 'Unknown Seller',
        'state': 'pending',
        'seller_uid': product.sellerId,
        'default_code':
            product.id ?? 'product-${DateTime.now().millisecondsSinceEpoch}',
        'meat_type': 'meat', // As specified in user's working code
      };

      // IMPLEMENTED: Use the exact Edge Function proxy structure from user's working code
      final response = await http.post(
        Uri.parse(_edgeFunctionUrl!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabaseService.currentClient.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'odoo_endpoint': '/web/dataset/call_kw',
          'data': {
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'model': 'product.template',
              'method': 'create',
              'args': [odooProductData],
            }
          },
          'session_id': _sessionId,
          'config': {
            'serverUrl': _config!.serverUrl,
            'database': _config!.database,
            'username': _config!.username,
            'password': _config!.password,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final odooId = data['result'] as int;
          print('Product synced to Odoo with ID: $odooId');

          // Fetch the created product with full details
          final createdProduct = await getOdooProductById(odooId);
          return createdProduct;
        } else {
          print('Odoo sync failed: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        print('HTTP error during Odoo sync: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return null;
    } catch (e) {
      print('Error syncing product to Odoo: $e');
      return null;
    }
  }

  // Get Odoo product by ID
  Future<OdooProduct?> getOdooProductById(int odooId) async {
    try {
      final result = await _callOdooAPI('product.template', 'read', [
        [odooId]
      ], kwargs: {
        'fields': [
          'name',
          'description',
          'list_price',
          'qty_available',
          'state',
          'default_code',
          'seller_id',
          'seller_uid',
          'meat_type',
          'create_date',
          'write_date',
        ]
      });

      if (result != null &&
          result['result'] != null &&
          result['result'].isNotEmpty) {
        return OdooProduct.fromMap(result['result'][0]);
      }
      return null;
    } catch (e) {
      print('Error fetching Odoo product: $e');
      return null;
    }
  }

  // CUSTOMER SYNCHRONIZATION METHODS

  // Create customer in Odoo using provided structure
  Future<int?> createCustomerInOdoo({
    required String name,
    required String email,
    required String phone,
    required bool isCompany,
  }) async {
    try {
      final customerData = {
        'name': name,
        'email': email,
        'phone': phone,
        'is_company': isCompany,
        'customer_rank': 1,
      };

      final response = await http.post(Uri.parse(_edgeFunctionUrl!),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${_supabaseService.currentClient.auth.currentSession?.accessToken}',
          },
          body: jsonEncode({
            'odoo_endpoint': '/web/dataset/call_kw',
            'data': {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'model': 'res.partner',
                'method': 'create',
                'args': [customerData],
              }
            },
            'session_id': _sessionId,
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final customerId = data['result'] as int;
          print('Customer created in Odoo with ID: $customerId');
          return customerId;
        }
      }

      return null;
    } catch (e) {
      print('Error creating customer in Odoo: $e');
      return null;
    }
  }

  // Test connection to Odoo
  Future<bool> testConnection() async {
    try {
      if (_config == null) {
        print('No configuration found, initializing with defaults...');
        return await initializeWithDefaults();
      }

      // Test by trying to authenticate
      return await _authenticate();
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Get connection status
  bool get isConnected =>
      _config != null && _userId != null && _sessionId != null;

  // Get all products from Odoo
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final result =
          await _callOdooAPI('product.template', 'search_read', [], kwargs: {
        'fields': [
          'name',
          'description',
          'list_price',
          'qty_available',
          'state',
          'default_code',
          'seller_id',
          'seller_uid',
          'meat_type',
          'create_date',
          'write_date',
          'categ_id',
          'barcode',
          'active',
          'standard_price',
        ]
      });

      if (result != null && result['result'] != null) {
        return List<Map<String, dynamic>>.from(result['result']);
      }
      return [];
    } catch (e) {
      print('Error fetching all products from Odoo: $e');
      return [];
    }
  }

  // Disconnect from Odoo
  Future<void> disconnect() async {
    _config = null;
    _userId = null;
    _sessionId = null;
    _edgeFunctionUrl = null;
  }
}