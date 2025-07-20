import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import './supabase_service.dart';

class AuthService {
  final SupabaseService _supabaseService = SupabaseService();

  // Get current user
  User? get currentUser => _supabaseService.currentClient.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'buyer',
    String? businessName,
  }) async {
    try {
      final client = await _supabaseService.client;

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'business_name': businessName,
        },
      );

      if (response.user != null) {
        // Profile will be created automatically via trigger
        return response;
      } else {
        throw Exception('Sign up failed');
      }
    } catch (error) {
      throw Exception('Sign up failed: $error');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final client = await _supabaseService.client;

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final client = await _supabaseService.client;
      await client.auth.signOut();
    } catch (error) {
      throw Exception('Sign out failed: $error');
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final client = await _supabaseService.client;
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return UserProfile.fromMap(response);
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  // Update user profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? businessName,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final client = await _supabaseService.client;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (businessName != null) updateData['business_name'] = businessName;
      if (address != null) updateData['address'] = address;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (pincode != null) updateData['pincode'] = pincode;

      final response = await client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromMap(response);
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      final client = await _supabaseService.client;
      await client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabaseService.currentClient.auth.onAuthStateChange;
  }
}
