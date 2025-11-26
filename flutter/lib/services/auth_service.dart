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
  Future<bool> checkEmailExists(String email) async {
    try {
      // Use the password reset flow to check if email exists
      // This is a safer way than trying to sign in with dummy password
      await _supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://compostkaki.vercel.app/reset-password',
      );
      // If no error, email exists
      return true;
    } catch (e) {
      final error = e.toString().toLowerCase();
      // If email doesn't exist, Supabase will return an error
      if (error.contains('user not found') || 
          error.contains('email not found') ||
          error.contains('invalid email')) {
        return false;
      }
      // For other errors (like rate limiting), assume email exists
      // This is safer - worst case user tries to sign in and gets proper error
      return true;
    }
  }
}

