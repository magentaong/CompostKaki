import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  User? get currentUser => _supabaseService.currentUser;
  bool get isAuthenticated => _supabaseService.isAuthenticated;
  
  AuthService() {
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
  
  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _supabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
      },
    );
    
    if (response.user != null) {
      // Create profile
      await _supabaseService.client.from('profiles').upsert({
        'id': response.user!.id,
        'first_name': firstName,
        'last_name': lastName,
      });
    }
    
    notifyListeners();
    return response;
  }
  
  // Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    notifyListeners();
    return response;
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabaseService.client.auth.signOut();
    notifyListeners();
  }

  // Update profile
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('No user logged in');

    // Update auth metadata
    await _supabaseService.client.auth.updateUser(
      UserAttributes(
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      ),
    );

    // Update profiles table
    await _supabaseService.client.from('profiles').upsert({
      'id': userId,
      'first_name': firstName,
      'last_name': lastName,
    });

    notifyListeners();
  }
  
  // Reset password - sends password reset email
  Future<void> resetPassword(String email) async {
    await _supabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://compostkaki.vercel.app/reset-password',
    );
  }

  // Check if email exists
  // Note: This tries to sign in with a dummy password to check if email exists
  // It will NOT send any emails, but will return an error that we can check
  Future<bool> checkEmailExists(String email) async {
    try {
      // Try to sign in with a clearly invalid password
      // This will fail, but the error message tells us if the email exists
      await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: '__EMAIL_CHECK_DUMMY_PASSWORD__',
      );
      // This should never succeed, but if it does, email exists
      return true;
    } catch (e) {
      final error = e.toString().toLowerCase();
      // If error says "invalid login credentials", email exists but password is wrong
      if (error.contains('invalid login credentials') || 
          error.contains('invalid credentials') ||
          error.contains('email and password')) {
        return true; // Email exists
      }
      // If error says "user not found" or "email not found", email doesn't exist
      if (error.contains('user not found') || 
          error.contains('email not found') ||
          error.contains('no user found')) {
        return false; // Email doesn't exist
      }
      // For other errors (network, etc.), assume email exists to be safe
      // Worst case: user tries to sign in and gets proper error message
      return true;
    }
  }

  // Delete user account
  // Calls the Next.js API endpoint to delete the account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    final session = _supabaseService.session;
    if (session == null) throw Exception('No active session');

    // API base URL - Update this to match your Next.js deployment URL
    // For production: 'https://compostkaki.vercel.app' (or your domain)
    // For development: 'http://localhost:3000' or 'http://YOUR_LOCAL_IP:3000'
    const apiBaseUrl = 'https://compostkaki.vercel.app';

    final url = Uri.parse('$apiBaseUrl/api/user/delete');
    
    try {
      // Use POST instead of DELETE for better compatibility
      // The API route supports both methods
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout: Failed to connect to server');
        },
      );

      if (response.statusCode == 200) {
        // Account deleted successfully
        // Sign out locally
        await signOut();
        notifyListeners();
      } else {
        // Handle error response
        String errorMessage = 'Failed to delete account';
        
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['error'] ?? errorMessage;
          } catch (e) {
            // If response is not valid JSON, use the raw body or status code
            errorMessage = 'Failed to delete account (Status: ${response.statusCode})';
            if (response.body.isNotEmpty) {
              errorMessage += ': ${response.body}';
            }
          }
        } else {
          errorMessage = 'Failed to delete account (Status: ${response.statusCode})';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network errors, timeouts, etc.
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

