import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
}

