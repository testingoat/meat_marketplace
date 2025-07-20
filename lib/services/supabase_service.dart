import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  final Future<void> _initFuture;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() : _initFuture = _initializeSupabase();

  static const String _supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Internal initialization logic
  static Future<void> _initializeSupabase() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.');
    }

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );

    _instance._client = Supabase.instance.client;
    _instance._isInitialized = true;
  }

  // Client getter (async)
  Future<SupabaseClient> get client async {
    if (!_isInitialized) {
      await _initFuture;
    }
    return _client;
  }

  // Convenience method for getting current client
  SupabaseClient get currentClient {
    if (!_isInitialized) {
      throw Exception(
          'Supabase not initialized. Call await supabaseService.client first.');
    }
    return _client;
  }

  // Auth helpers
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => _client.auth.currentUser != null;

  // Current user ID getter
  String? get currentUserId => _client.auth.currentUser?.id;

  // Instance properties for accessing static constants
  String get supabaseUrl => SupabaseService._supabaseUrl;
  String get supabaseKey => SupabaseService._supabaseAnonKey;

  // Static getters for accessing configuration from other classes
  static String get staticSupabaseUrl => _supabaseUrl;
  static String get staticSupabaseKey => _supabaseAnonKey;

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
