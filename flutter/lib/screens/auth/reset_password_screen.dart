import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? token; // For deep linking support

  const ResetPasswordScreen({
    super.key,
    this.email,
    this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  bool _hasSession = false; // Has either authenticated or recovery session

  @override
  void initState() {
    super.initState();
    _checkSession();
    _handleDeepLink();
    
    // Listen for auth state changes (e.g., when user clicks reset link)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkSession();
      }
    });
  }
  
  void _handleDeepLink() async {
    // Check if we have tokens from deep link query parameters
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait a bit to ensure context is fully available
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) {
        print('⚠️ [RESET PASSWORD] Widget not mounted, skipping deep link handling');
        return;
      }
      
      try {
        // Get tokens from GoRouter state (passed via deep link)
        final router = GoRouter.of(context);
        final location = router.routerDelegate.currentConfiguration.uri.toString();
        print('🔗 [RESET PASSWORD] Current route location: $location');
        
        final uri = Uri.parse(location);
        final accessToken = uri.queryParameters['access_token'];
        final refreshToken = uri.queryParameters['refresh_token'];
        final type = uri.queryParameters['type'];
        
        print('🔗 [RESET PASSWORD] Tokens from route - type: $type, hasAccessToken: ${accessToken != null}, hasRefreshToken: ${refreshToken != null}');
        
        // If we have recovery tokens from deep link, set the session
        if (type == 'recovery' && accessToken != null && refreshToken != null) {
          print('🔗 [RESET PASSWORD] Setting recovery session from deep link tokens...');
          
          if (!mounted) return;
          
          final authService = context.read<AuthService>();
          final success = await authService.setRecoverySession(accessToken, refreshToken);
          
          if (success) {
            print('✅ Recovery session set successfully');
          } else {
            print('⚠️ Failed to set recovery session');
          }
          
          // Re-check session after setting it
          if (mounted) {
            _checkSession();
          }
        } else {
          // Check if we already have a recovery session (from URL hash or other means)
          final supabase = Supabase.instance.client;
          final session = supabase.auth.currentSession;
          
          print('🔗 [RESET PASSWORD] Checking existing session - hasSession: ${session != null}');
          
          // If we have a session but user email is not confirmed, it's a recovery session
          if (session != null && session.user.emailConfirmedAt == null) {
            print('🔗 [RESET PASSWORD] Found recovery session');
            // This is a recovery session from the reset link
            if (mounted) {
              setState(() {
                _hasSession = true;
              });
            }
          }
        }
      } catch (e, stackTrace) {
        print('❌ Error handling deep link: $e');
        print('Stack trace: $stackTrace');
        // Fallback: just check for existing session
        if (mounted) {
          _checkSession();
        }
      }
    });
  }
  
  void _checkSession() {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final authService = context.read<AuthService>();
    
    // Check if user has a session (authenticated or recovery)
    _hasSession = session != null;
    
    // Pre-fill email if provided
    if (widget.email != null && _emailController.text.isEmpty) {
      _emailController.text = widget.email!;
    } else if (_hasSession && session != null && session.user.email != null) {
      // Pre-fill with session email
      if (_emailController.text.isEmpty) {
        _emailController.text = session.user.email ?? '';
      }
    } else if (authService.isAuthenticated && authService.currentUser?.email != null) {
      // Pre-fill with current user's email if authenticated
      if (_emailController.text.isEmpty) {
        _emailController.text = authService.currentUser?.email ?? '';
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.resetPassword(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Please check your inbox and click the link to reset your password.'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 4),
          ),
        );
        // Navigate to login (use go instead of pop to avoid "nothing to pop" error)
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      // Check if user has a valid session (authenticated or recovery session)
      if (session != null) {
        // Update password - works for both authenticated users and recovery sessions
        await authService.updatePassword(password);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully! Please login with your new password.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          
          // Check if this was a recovery session (user not fully authenticated)
          final isRecoverySession = session.user.emailConfirmedAt == null;
          
          if (isRecoverySession) {
            // Recovery session - sign out and go to login
            await authService.signOut();
            context.go('/login');
          } else {
            // Fully authenticated user - go back to profile
            // Use go instead of pop to avoid "nothing to pop" error when opened via deep link
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          }
        }
      } else {
        // No session - user needs to click the reset link first
        throw Exception('Please click the reset link in your email first, then you can set your new password here.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGreen),
          onPressed: () {
            // Use go instead of pop to avoid "nothing to pop" error when opened via deep link
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.lock_reset,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  _hasSession ? 'Reset Your Password' : 'Reset Your Password',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _hasSession
                      ? 'Enter your new password below.'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Email field (only shown if no session, or always visible for context)
                if (!_hasSession) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: AppTheme.primaryGreen),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Password fields (shown when user has a session - authenticated or recovery)
                if (_hasSession) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.textGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.textGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _hasSession
                          ? _updatePassword
                          : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _hasSession ? 'Update Password' : 'Send Reset Link',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

