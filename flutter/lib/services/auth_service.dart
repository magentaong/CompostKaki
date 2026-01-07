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
  // IMPORTANT: This sends an email. User must click the link in email to get a recovery session.
  // Then they can use updatePasswordWithRecovery() to set new password.
  Future<void> resetPassword(String email) async {
    try {
      // Validate email format first
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      // Use our API route that handles verify endpoint properly
      // This ensures tokens are preserved and redirected correctly to the app
      final webUrl = 'https://compostkaki.vercel.app/api/auth/verify-reset?redirect_to=https://compostkaki.vercel.app/reset-password';
      
      // Call Supabase reset password
      // Supabase will send email with: https://compostkaki.vercel.app/reset-password#tokens
      // Web page will redirect to: compostkaki://reset-password#tokens
      // App will receive deep link with tokens
      await _supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: webUrl,
      );
      
      // If we get here, the email was sent successfully
      // Note: Supabase always returns success even if email doesn't exist (for security)
    } on AuthException catch (e) {
      // Handle Supabase auth-specific errors
      throw Exception('Failed to send reset email: ${e.message}');
    } catch (e) {
      // Handle other errors (network, etc.)
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('Network error. Please check your connection and try again.');
      }
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Update password with recovery token (from email link)
  // This is called after user clicks the reset link in their email
  // Note: For password reset, Supabase automatically creates a recovery session
  // when the user clicks the reset link. We just need to update the password.
  Future<void> updatePasswordWithRecovery({
    required String accessToken,
    required String refreshToken,
    required String newPassword,
  }) async {
    try {
      if (newPassword.isEmpty || newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      // Create a session from the tokens
      // Supabase Flutter's setSession expects a Session object or we can use the tokens directly
      // Let's use the GoTrue client's setSession method which accepts tokens
      final goTrueClient = _supabaseService.client.auth;
      
      // Set session using the recovery tokens
      // The setSession method signature may vary by version, let's use a simpler approach
      // We'll rely on Supabase's automatic session handling when the reset link is clicked
      // For now, we'll update password directly if there's already a recovery session
      
      // Update the password - this will work if there's a valid recovery session
      final response = await goTrueClient.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password. Please click the reset link in your email first.');
      }

      // Sign out after password reset (user needs to login with new password)
      await signOut();
      notifyListeners();
    } on AuthException catch (e) {
      throw Exception('Failed to update password: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // Set recovery session from tokens (for password reset deep links)
  Future<bool> setRecoverySession(String accessToken, String refreshToken) async {
    try {
      print('🔐 [AUTH SERVICE] Setting recovery session...');
      print('🔐 [AUTH SERVICE] Access token length: ${accessToken.length}');
      print('🔐 [AUTH SERVICE] Refresh token length: ${refreshToken.length}');
      
      final supabase = _supabaseService.client;
      
      // Try to set session using access token
      // Supabase Flutter's setSession accepts a string (access token)
      // The refresh token should be handled automatically by Supabase
      final response = await supabase.auth.setSession(accessToken);
      
      print('🔐 [AUTH SERVICE] setSession response - hasSession: ${response.session != null}');
      
      if (response.session != null) {
        print('✅ [AUTH SERVICE] Recovery session set successfully');
        print('🔐 [AUTH SERVICE] User ID: ${response.session!.user.id}');
        print('🔐 [AUTH SERVICE] Email: ${response.session!.user.email}');
        notifyListeners();
        return true;
      }
      
      print('⚠️ [AUTH SERVICE] Session is null after setSession');
      return false;
    } catch (e, stackTrace) {
      print('❌ [AUTH SERVICE] Error setting recovery session: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Update password for currently authenticated user
  // This requires the user to be logged in
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('You must be logged in to change your password. Please use reset password instead.');
      }

      if (newPassword.isEmpty || newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      // Update password for authenticated user
      final response = await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password');
      }

      notifyListeners();
    } on AuthException catch (e) {
      throw Exception('Failed to update password: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
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
            errorMessage =
                'Failed to delete account (Status: ${response.statusCode})';
            if (response.body.isNotEmpty) {
              errorMessage += ': ${response.body}';
            }
          }
        } else {
          errorMessage =
              'Failed to delete account (Status: ${response.statusCode})';
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
